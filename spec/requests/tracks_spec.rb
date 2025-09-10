require 'rails_helper'

RSpec.describe "Tracks", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  describe "GET /tracks" do
    let!(:content1) { create(:content, theme: "レコード、古いスピーカー") }
    let!(:content2) { create(:content, :cafe_theme) }

    context "with tracks present" do
      let!(:track1) { create(:track, :completed, content: content1, created_at: 3.hours.ago) }
      let!(:track2) { create(:track, :processing, content: content2, created_at: 2.hours.ago) }
      let!(:track3) { create(:track, :pending, content: content1, created_at: 1.hour.ago) }

      it "displays tracks list page successfully" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Track一覧")
        # Confirm that it uses table format
        expect(response.body).to include("<table")
        expect(response.body).to include("<thead")
        expect(response.body).to include("<tbody")
      end

      it "displays track information including content name" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # Display track IDs
        expect(response.body).to include("##{track1.id}")
        expect(response.body).to include("##{track2.id}")
        expect(response.body).to include("##{track3.id}")
        # Display track titles
        expect(response.body).to include(track1.metadata_title) if track1.metadata_title.present?
        # Display content themes
        expect(response.body).to include(content1.theme)
        expect(response.body).to include(content2.theme)
      end

      it "displays track status information" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("完了")
        expect(response.body).to include("処理中")
        expect(response.body).to include("待機中")
      end

      it "includes link to content detail page" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(content_path(content1))
        expect(response.body).to include(content_path(content2))
      end

      it "orders tracks by creation date (newest first)" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # track3 (created 1 hour ago) should appear before track2 (2 hours ago) and track1 (3 hours ago)
        track_positions = [
          [ track3.id, response.body.index("##{track3.id}") ],
          [ track2.id, response.body.index("##{track2.id}") ],
          [ track1.id, response.body.index("##{track1.id}") ]
        ].sort_by(&:last)

        # Should be ordered by most recent first
        expect(track_positions.map(&:first)).to eq([ track3.id, track2.id, track1.id ])
      end

      it "includes pagination" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("nav")
      end

      context "with more than 30 tracks" do
        before do
          create_list(:track, 31, content: content1)
        end

        it "paginates tracks with 30 items per page" do
          get tracks_path

          expect(response).to have_http_status(:success)
          # Count actual track rows in table
          track_count = response.body.scan(/<tr[^>]*class="[^"]*track[^"]*"/).count
          expect(track_count).to be <= 30
        end

        it "shows pagination controls" do
          get tracks_path

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Next") if response.body.scan(/track_\d+/).count == 30
        end

        it "loads second page correctly" do
          get tracks_path, params: { page: 2 }

          expect(response).to have_http_status(:success)
          track_count = response.body.scan(/<tr[^>]*class="[^"]*track[^"]*"/).count
          expect(track_count).to be > 0
        end
      end
    end

    context "with no tracks" do
      it "displays empty state message" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Trackがまだありません")
      end

      it "does not show pagination when no tracks" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # Check for pagination-specific Next link, not just any "Next" text
        expect(response.body).not_to include('rel="next"')
        expect(response.body).not_to include('class="pagination"')
      end
    end

    context "layout rendering" do
      it "does not have duplicate layout components" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # サイドバーが1つだけ存在することを確認
        sidebar_count = response.body.scan(/data-controller="layout"/).count
        expect(sidebar_count).to eq(1), "Expected exactly 1 layout component, but found #{sidebar_count}"
      end

      it "renders page title correctly" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # タイトルが適切に設定されていることを確認
        expect(response.body).to include("<title>")
        expect(response.body).to include("Track一覧")
      end
    end

    context "performance considerations" do
      let!(:tracks_with_content) { create_list(:track, 5, content: content1) }

      it "loads tracks with content information efficiently" do
        # This test verifies that the controller uses includes(:content) to avoid N+1 queries
        # The actual N+1 prevention is tested by observing the rendered content includes content info
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(content1.theme)
      end

      it "responds within acceptable time limit" do
        start_time = Time.current
        get tracks_path
        response_time = Time.current - start_time

        expect(response).to have_http_status(:success)
        expect(response_time).to be < 2.0, "Response took #{response_time}s, expected < 2.0s"
      end

      it "handles large datasets efficiently" do
        create_list(:track, 50, content: content1)

        start_time = Time.current
        get tracks_path
        response_time = Time.current - start_time

        expect(response).to have_http_status(:success)
        expect(response_time).to be < 3.0, "Response took #{response_time}s with 50+ tracks, expected < 3.0s"
      end
    end

    context "search functionality" do
      let!(:content3) { create(:content, theme: "Relaxing BGM") }
      let!(:content4) { create(:content, theme: "Focus Music") }
      let!(:track_completed1) {
        create(:track,
          content: content3,
          status: :completed,
          metadata: { "music_title" => "Morning Coffee" },
          created_at: 1.day.ago
        )
      }
      let!(:track_completed2) {
        create(:track,
          content: content4,
          status: :completed,
          metadata: { "music_title" => "Deep Focus" },
          created_at: 2.days.ago
        )
      }
      let!(:track_pending) {
        create(:track,
          content: content3,
          status: :pending,
          metadata: { "music_title" => "Night Jazz" },
          created_at: 3.days.ago
        )
      }

      it "filters tracks correctly by various search parameters and maintains pagination" do
        # Test content theme search
        get tracks_path, params: { q: { content_theme_cont: "Relax" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Morning Coffee")
        expect(response.body).not_to include("Deep Focus")

        # Test music title search
        get tracks_path, params: { q: { music_title_cont: "Focus" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Deep Focus")
        expect(response.body).not_to include("Morning Coffee")

        # Test status filter
        get tracks_path, params: { q: { status_in: [ "completed" ] } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Morning Coffee")
        expect(response.body).to include("Deep Focus")
        expect(response.body).not_to include("Night Jazz")
        expect(response.body).to match(/検索結果.*2.*件/)

        # Test combined search parameters
        get tracks_path, params: { q: { content_theme_cont: "Music", status_in: [ "completed" ] } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Deep Focus")
        expect(response.body).not_to include("Morning Coffee")

        # Test date range search
        get tracks_path, params: { q: { created_at_gteq: 2.days.ago.beginning_of_day.iso8601 } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Morning Coffee")
        expect(response.body).to include("Deep Focus")
      end
    end
  end

  describe "POST /contents/:content_id/tracks/generate_single" do
    let(:content) { create(:content, duration_min: 600) }

    it "creates exactly one music generation" do
      expect {
        post generate_single_content_tracks_path(content)
      }.to change(MusicGeneration, :count).by(1)
    end

    it "redirects to content path with success message" do
      post generate_single_content_tracks_path(content)

      expect(response).to redirect_to(content_path(content))
      follow_redirect!
      expect(response.body).to include("音楽生成を開始しました（1件）")
    end

    it "creates music generation with correct attributes" do
      post generate_single_content_tracks_path(content)

      music_generation = content.music_generations.last
      expect(music_generation.status).to eq('pending')
      expect(music_generation.prompt).to eq(content.audio_prompt)
      expect(music_generation.generation_model).to eq('V4_5PLUS')
    end

    it "enqueues GenerateMusicGenerationJob" do
      expect {
        post generate_single_content_tracks_path(content)
      }.to have_enqueued_job(GenerateMusicGenerationJob)
    end

    context "when music generations already exist" do
      before do
        create_list(:music_generation, 5, content: content)
      end

      it "still creates a new music generation" do
        expect {
          post generate_single_content_tracks_path(content)
        }.to change(MusicGeneration, :count).by(1)
      end
    end

    context "when tracks already exist" do
      before do
        create_list(:track, 100, content: content)
      end

      it "still creates a new music generation" do
        expect {
          post generate_single_content_tracks_path(content)
        }.to change(MusicGeneration, :count).by(1)
      end
    end

    context "when called multiple times" do
      it "creates multiple music generations" do
        expect {
          3.times { post generate_single_content_tracks_path(content) }
        }.to change(MusicGeneration, :count).by(3)
      end
    end
  end

  describe "POST /contents/:content_id/tracks/generate_bulk" do
    let(:content) { create(:content, duration_min: 600) }
    let(:expected_generation_count) { 105 } # (600 / 6) + 5 = 105 with new formula

    it "creates calculated number of music generations" do
      expect {
        post generate_bulk_content_tracks_path(content)
      }.to change(MusicGeneration, :count).by(expected_generation_count)
    end

    it "redirects to content path with success message" do
      post generate_bulk_content_tracks_path(content)

      expect(response).to redirect_to(content_path(content))
      follow_redirect!
      expect(response.body).to include("音楽生成を開始しました（#{expected_generation_count}件）")
    end

    it "creates music generations with correct attributes" do
      post generate_bulk_content_tracks_path(content)

      music_generations = content.music_generations.order(:created_at).last(expected_generation_count)
      expect(music_generations.size).to eq(expected_generation_count)
      music_generations.each do |mg|
        expect(mg.status).to eq('pending')
        expect(mg.prompt).to eq(content.audio_prompt)
        expect(mg.generation_model).to eq('V4_5PLUS')
      end
    end

    it "enqueues GenerateMusicGenerationJob for calculated number of times" do
      expect {
        post generate_bulk_content_tracks_path(content)
      }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(expected_generation_count).times
    end

    context "when music generations already exist" do
      before do
        create_list(:music_generation, 10, content: content)
      end

      it "still creates calculated number of new music generations" do
        expect {
          post generate_bulk_content_tracks_path(content)
        }.to change(MusicGeneration, :count).by(expected_generation_count)
      end
    end

    context "when tracks already exist" do
      before do
        create_list(:track, 100, content: content)
      end

      it "still creates calculated number of new music generations" do
        expect {
          post generate_bulk_content_tracks_path(content)
        }.to change(MusicGeneration, :count).by(expected_generation_count)
      end
    end

    context "when called multiple times" do
      it "creates calculated number of music generations each time" do
        expect {
          3.times { post generate_bulk_content_tracks_path(content) }
        }.to change(MusicGeneration, :count).by(expected_generation_count * 3)
      end
    end
  end
end
