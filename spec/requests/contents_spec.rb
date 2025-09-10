require 'rails_helper'

RSpec.describe "Contents", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end
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
      # Ensure database is clean
      Content.destroy_all

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

      it "displays new card design with icons" do
        content = create(:content, theme: "Test Content with Icons", duration_min: 10)
        create(:artwork, content: content)
        create(:track, content: content, status: :completed, duration_sec: 400)
        create(:track, content: content, status: :completed, duration_sec: 300)
        create(:video, content: content, status: :completed)

        get contents_path

        expect(response).to have_http_status(:success)
        # New design includes SVG icons
        expect(response.body).to include('svg')
        # Should not include old progress bar elements
        # Check that new icon-based design is used
        expect(response.body).not_to include('トラック進捗')
      end
    end
  end

  describe "GET /contents/:id" do
    let(:content) { create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト") }

    it "displays content details including new fields" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("テストテーマ")
      expect(response.body).to include("10 分")  # スペースが追加された
      expect(response.body).to include("テスト用プロンプト")
      expect(response.body).to include("作成日時")
      expect(response.body).to include("更新日時")
    end

    it "does not display complex status overview" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("制作ステータス")
      expect(response.body).not_to include("トラック進捗")
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
              duration_min: 5,
              audio_prompt: "リラックスできるBGMを生成してください"
            }
          }
        }.to change(Content, :count).by(1)

        expect(response).to redirect_to(Content.last)
        follow_redirect!
        expect(response.body).to include("Content was successfully created")

        content = Content.last
        expect(content.theme).to eq("新しいテーマ")
        expect(content.duration_min).to eq(5)
        expect(content.audio_prompt).to eq("リラックスできるBGMを生成してください")
      end
    end

    context "with invalid params" do
      it "renders new template with unprocessable_content status for validation errors" do
        # Test multiple validation failures
        post contents_path, params: { content: { theme: "", duration_min: 0, audio_prompt: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")

        # Verify each individual validation failure returns same HTTP status
        post contents_path, params: { content: { theme: "test", duration_min: 5, audio_prompt: "" } }
        expect(response).to have_http_status(:unprocessable_content)
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
    let(:content) { create(:content, theme: "古いテーマ", duration_min: 3, audio_prompt: "古いプロンプト") }

    context "with valid params" do
      it "updates the content with all fields" do
        patch content_path(content), params: {
          content: {
            theme: "更新されたテーマ",
            duration_min: 10,
            audio_prompt: "更新されたプロンプト"
          }
        }

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("Content was successfully updated")
        expect(response.body).to include("更新されたテーマ")
        expect(response.body).to include("10 分")
        expect(response.body).to include("更新されたプロンプト")
      end
    end

    context "with invalid params" do
      it "renders edit template with unprocessable_content status for validation errors" do
        # Test multiple validation failures
        patch content_path(content), params: { content: { theme: "", duration_min: 0 } }
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
    let(:content) { create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト") }

    context "with valid content" do
      it "generates music generations successfully" do
        # For duration 10: (10 / (3*2)) + 5 = 1.67 + 5 = 6.67 => 7 MusicGeneration
        expect {
          post generate_tracks_content_path(content)
        }.to change { content.music_generations.count }.by(7)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("音楽生成を開始しました（7件）")
      end

      it "enqueues GenerateMusicGenerationJob for each music generation" do
        # For duration 10: 7 music generations needed
        expect {
          post generate_tracks_content_path(content)
        }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(7).times
      end

      it "creates music generations with pending status" do
        post generate_tracks_content_path(content)

        expect(content.music_generations.all?(&:pending?)).to be true
      end
    end

    context "with invalid content" do
      it "redirects with appropriate error messages for missing prerequisites" do
        # Test missing duration
        invalid_content1 = create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト")
        invalid_content1.update_column(:duration_min, 0)

        post generate_tracks_content_path(invalid_content1)
        expect(response).to redirect_to(invalid_content1)
        follow_redirect!
        expect(response.body).to include("動画の長さが設定されていません")

        # Test missing audio_prompt
        invalid_content2 = create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト")
        invalid_content2.update_column(:audio_prompt, "")

        post generate_tracks_content_path(invalid_content2)
        expect(response).to redirect_to(invalid_content2)
        follow_redirect!
        expect(response.body).to include("音楽生成プロンプトが設定されていません")
      end
    end
  end

  describe "POST /contents/:id/generate_single_track" do
    let(:content) { create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト") }

    context "with valid content" do
      it "generates a music generation successfully" do
        expect {
          post generate_single_track_content_path(content)
        }.to change { content.music_generations.count }.by(1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("音楽生成を開始しました（1件）")
      end

      it "enqueues GenerateMusicGenerationJob for the created music generation" do
        expect {
          post generate_single_track_content_path(content)
        }.to have_enqueued_job(GenerateMusicGenerationJob).once
      end

      it "creates music generation with pending status" do
        post generate_single_track_content_path(content)

        expect(content.music_generations.last.status.pending?).to be true
      end
    end

    context "with invalid content" do
      it "redirects with appropriate error messages for missing prerequisites" do
        # Test missing duration
        invalid_content1 = create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト")
        invalid_content1.update_column(:duration_min, 0)

        post generate_single_track_content_path(invalid_content1)
        expect(response).to redirect_to(invalid_content1)
        follow_redirect!
        expect(response.body).to include("動画の長さが設定されていません")

        # Test missing audio_prompt
        invalid_content2 = create(:content, theme: "テストテーマ", duration_min: 10, audio_prompt: "テスト用プロンプト")
        invalid_content2.update_column(:audio_prompt, "")

        post generate_single_track_content_path(invalid_content2)
        expect(response).to redirect_to(invalid_content2)
        follow_redirect!
        expect(response.body).to include("音楽生成プロンプトが設定されていません")
      end
    end
  end
end
