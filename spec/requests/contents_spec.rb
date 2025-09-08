require 'rails_helper'

RSpec.describe "Contents", type: :request do
  describe "GET /contents" do
    it "displays contents list" do
      create(:content, theme: "朝のリラックスBGM")
      create(:content, theme: "夜のチルアウト")

      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("コンテンツ一覧")
      expect(response.body).to include("朝のリラックスBGM")
      expect(response.body).to include("夜のチルアウト")
    end

    it "displays empty state when no contents" do
      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("コンテンツがまだありません")
    end

    it "includes status filter component when contents exist" do
      create(:content)
      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="status-filter"')
    end

    it "includes status summary" do
      create(:content, theme: "Test Content")
      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("件のコンテンツ")
    end

    context "with status filter parameter" do
      it "includes correct selected status in filter component when status parameter is provided" do
        create(:content)
        get contents_path, params: { status: 'completed' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-status-filter-selected-value="completed"')
      end

      it "defaults to 'all' status in filter component when no status parameter" do
        create(:content)
        get contents_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-status-filter-selected-value="all"')
      end
    end

    context "with associated data" do
      it "loads successfully with tracks and artwork" do
        content = create(:content)
        create(:track, content: content)
        create(:artwork, content: content)

        get contents_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(content.theme)
      end
    end
  end

  describe "GET /contents/:id" do
    let(:content) { create(:content, theme: "テストテーマ", duration: 10, audio_prompt: "テスト用プロンプト") }

    it "displays content details including new fields" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("テストテーマ")
      expect(response.body).to include("10分")
      expect(response.body).to include("テスト用プロンプト")
      expect(response.body).to include("作成日時")
      expect(response.body).to include("更新日時")
    end

    it "displays enhanced status overview" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("制作ステータス")
      expect(response.body).to include("トラック進捗")
    end

    it "displays status badge" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-status=')
    end

    it "loads successfully with associated data" do
      create(:track, content: content)
      create(:artwork, content: content)

      get content_path(content)

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /contents/new" do
    it "displays new content form" do
      get new_content_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("form")
    end
  end

  describe "POST /contents" do
    context "with valid params" do
      it "creates a new content with all required fields" do
        expect {
          post contents_path, params: {
            content: {
              theme: "新しいテーマ",
              duration: 5,
              audio_prompt: "リラックスできるBGMを生成してください"
            }
          }
        }.to change(Content, :count).by(1)

        expect(response).to redirect_to(Content.last)
        follow_redirect!
        expect(response.body).to include("Content was successfully created")

        content = Content.last
        expect(content.theme).to eq("新しいテーマ")
        expect(content.duration).to eq(5)
        expect(content.audio_prompt).to eq("リラックスできるBGMを生成してください")
      end
    end

    context "with invalid params" do
      it "renders new template with errors when theme is blank" do
        post contents_path, params: { content: { theme: "", duration: 5, audio_prompt: "test" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end

      it "renders new template with errors when duration is invalid" do
        post contents_path, params: { content: { theme: "test", duration: 0, audio_prompt: "test" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end

      it "renders new template with errors when audio_prompt is blank" do
        post contents_path, params: { content: { theme: "test", duration: 5, audio_prompt: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end
    end
  end

  describe "GET /contents/:id/edit" do
    let(:content) { create(:content) }

    it "displays edit form" do
      get edit_content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("form")
      expect(response.body).to include(content.theme)
    end
  end

  describe "PATCH /contents/:id" do
    let(:content) { create(:content, theme: "古いテーマ", duration: 3, audio_prompt: "古いプロンプト") }

    context "with valid params" do
      it "updates the content with all fields" do
        patch content_path(content), params: {
          content: {
            theme: "更新されたテーマ",
            duration: 10,
            audio_prompt: "更新されたプロンプト"
          }
        }

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("Content was successfully updated")
        expect(response.body).to include("更新されたテーマ")
        expect(response.body).to include("10分")
        expect(response.body).to include("更新されたプロンプト")
      end
    end

    context "with invalid params" do
      it "renders edit template with errors when theme is blank" do
        patch content_path(content), params: { content: { theme: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end

      it "renders edit template with errors when duration is invalid" do
        patch content_path(content), params: { content: { duration: 0 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end
    end
  end

  describe "DELETE /contents/:id" do
    let!(:content) { create(:content) }

    it "destroys the content" do
      expect {
        delete content_path(content)
      }.to change(Content, :count).by(-1)

      expect(response).to redirect_to(contents_path)
      follow_redirect!
      expect(response.body).to include("Content was successfully destroyed")
    end
  end

  describe "POST /contents/:id/generate_tracks" do
    let(:content) { create(:content, theme: "テストテーマ", duration: 10, audio_prompt: "テスト用プロンプト") }

    context "with valid content" do
      it "generates tracks successfully" do
        expect {
          post generate_tracks_content_path(content)
        }.to change { content.tracks.count }.by(7) # (10 / (3*2)) + 5 = 7

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("7 tracks were queued for generation")
      end

      it "enqueues GenerateTrackJob for each created track" do
        expect {
          post generate_tracks_content_path(content)
        }.to have_enqueued_job(GenerateTrackJob).exactly(7).times
      end

      it "creates tracks with pending status" do
        post generate_tracks_content_path(content)

        expect(content.tracks.all?(&:pending?)).to be true
      end
    end

    context "with invalid content" do
      context "when tracks are already being generated" do
        before do
          create(:track, content: content, status: :processing)
        end

        it "redirects with error message" do
          post generate_tracks_content_path(content)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("Content already has tracks being generated")
        end
      end

      context "when track limit would be exceeded" do
        before do
          create_list(:track, 95, content: content)
        end

        it "redirects with error message" do
          post generate_tracks_content_path(content)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("Content would exceed maximum track limit")
        end
      end
    end
  end

  describe "POST /contents/:id/generate_single_track" do
    let(:content) { create(:content, theme: "テストテーマ", duration: 10, audio_prompt: "テスト用プロンプト") }

    context "with valid content" do
      it "generates a music generation successfully" do
        expect {
          post generate_single_track_content_path(content)
        }.to change { content.music_generations.count }.by(1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("Music generation was queued")
      end

      it "enqueues GenerateMusicJob for the created music generation" do
        expect {
          post generate_single_track_content_path(content)
        }.to have_enqueued_job(GenerateMusicJob).once
      end

      it "creates music generation with pending status" do
        post generate_single_track_content_path(content)

        expect(content.music_generations.last.status.pending?).to be true
      end
    end

    context "with invalid content" do
      context "when tracks are already being generated" do
        before do
          create(:track, content: content, status: :processing)
        end

        it "redirects with error message" do
          post generate_single_track_content_path(content)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("Content already has tracks being generated")
        end
      end

      context "when track limit would be exceeded" do
        before do
          create_list(:track, 100, content: content)
        end

        it "redirects with error message" do
          post generate_single_track_content_path(content)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("Content would exceed maximum track limit")
        end
      end

      context "when content has 99 tracks" do
        before do
          create_list(:track, 99, content: content)
        end

        it "allows generating one more music generation" do
          expect {
            post generate_single_track_content_path(content)
          }.to change { content.music_generations.count }.by(1)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("Music generation was queued")
        end
      end
    end
  end
end
