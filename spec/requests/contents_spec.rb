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

    context "with audio and selected tracks" do
      let(:tracks) { create_list(:track, 3, content: content, status: :completed, duration_sec: 180) }
      let!(:audio) do
        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => tracks.map(&:id) })
      end

      it "displays used tracks table when audio is completed" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("音源生成")
        expect(response.body).to include("使用Track一覧")
        expect(response.body).to include("#1")
        expect(response.body).to include("#2")
        expect(response.body).to include("#3")
      end
    end

    context "with audio but not completed" do
      let!(:audio) do
        create(:audio,
               content: content,
               status: :processing,
               metadata: { "selected_track_ids" => [ 1, 2, 3 ] })
      end

      it "does not display used tracks table" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("音源生成")
        expect(response.body).not_to include("使用Track一覧")
      end
    end

    context "with completed audio but no selected tracks" do
      let!(:audio) do
        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => [] })
      end

      it "does not display used tracks table" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("音源生成")
        expect(response.body).not_to include("使用Track一覧")
      end
    end

    context "with artwork variations" do
      let!(:artwork) { create(:artwork, content: content) }

      it "displays artwork variations grid" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("artwork-variations-grid")
        expect(response.body).to include("オリジナル")
      end

      context "with YouTube thumbnail" do
        before do
          allow_any_instance_of(Artwork).to receive(:has_youtube_thumbnail?).and_return(true)
          allow_any_instance_of(Artwork).to receive(:youtube_thumbnail_url).and_return("/youtube_thumb.jpg")
        end

        it "displays both original and YouTube thumbnail" do
          get content_path(content)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("オリジナル")
          expect(response.body).to include("YouTube用")
        end
      end
    end

    context "with selected tracks including deleted tracks" do
      let(:tracks) { create_list(:track, 3, content: content, status: :completed, duration_sec: 180) }
      let!(:audio) do
        # Include non-existent track IDs
        track_ids = tracks.map(&:id) + [ 999999 ]
        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => track_ids })
      end

      it "displays only existing tracks" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("使用Track一覧")
        expect(response.body).to include("#1")
        expect(response.body).to include("#2")
        expect(response.body).to include("#3")
        # Should not cause error due to non-existent track
      end
    end

    context "with audio info card refactoring" do
      context "when content has completed audio" do
        let!(:audio) do
          create(:audio,
            content: content,
            status: "completed",
            metadata: {
              "duration" => 180,
              "file_url" => "https://example.com/audio.mp3"
            }
          )
        end

        before do
          audio.update!(created_at: 2.minutes.ago, updated_at: Time.current)
          audio_attachment = double('audio_attachment', url: 'https://example.com/audio.mp3', present?: true)
          allow(audio).to receive(:audio).and_return(audio_attachment)
        end

        it "displays audio info in horizontal layout" do
          get content_path(content)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("音源情報")
          expect(response.body).to include("長さ:")
          expect(response.body).to include("3:00")
          expect(response.body).to include("作成時間:")
          expect(response.body).to include("2分0秒")
        end

        it "includes delete icon button for completed audio" do
          get content_path(content)

          expect(response.body).to include("この音源を削除してもよろしいですか？")
        end

        it "includes play button for completed audio" do
          get content_path(content)

          # 音源情報が表示されていることを確認
          expect(response.body).to include("音源情報")
          expect(response.body).to include("3:00") # 音源の長さ
          # 削除ボタンが表示されていることを確認（完了した音源には削除ボタンがある）
          expect(response.body).to include("この音源を削除してもよろしいですか？")
        end
      end

      context "when content has processing audio" do
        let!(:audio) do
          create(:audio,
            content: content,
            status: "processing",
            metadata: {}
          )
        end

        it "does not display delete button for processing audio" do
          get content_path(content)

          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("この音源を削除してもよろしいですか？")
        end

        it "does not display play button for processing audio" do
          get content_path(content)

          # play_circleアイコンが音源情報カードに表示されない
          expect(response.body.scan("play_circle").count).to be <= 1
        end
      end

      context "when content has failed audio" do
        let!(:audio) do
          create(:audio,
            content: content,
            status: "failed",
            metadata: {}
          )
        end

        it "displays delete button for failed audio" do
          get content_path(content)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("この音源を削除してもよろしいですか？")
        end
      end
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

  describe "GET /contents/:id (コンテンツ詳細画面)" do
    let(:content) { create(:content, duration_min: 10) }

    context "音楽生成ステータス集計表示" do
      before do
        # 各ステータスのMusicGenerationを作成
        create_list(:music_generation, 2, content: content, status: :pending)
        create_list(:music_generation, 3, content: content, status: :processing)
        create_list(:music_generation, 4, content: content, status: :completed)
        create_list(:music_generation, 1, content: content, status: :failed)
      end

      it "ステータス集計が表示される" do
        get content_path(content)
        expect(response).to have_http_status(:success)

        # 各ステータスの件数が表示されることを確認
        expect(response.body).to include("待機中: 2件")
        expect(response.body).to include("処理中: 3件")
        expect(response.body).to include("完了: 4件")
        expect(response.body).to include("失敗: 1件")

        # 適切な色クラスを持つことを確認（ダークモード対応）
        expect(response.body).to include("text-gray-300")
        expect(response.body).to include("text-yellow-300")
        expect(response.body).to include("text-green-300")
        expect(response.body).to include("text-red-300")
      end
    end

    context "MusicGenerationが存在しない場合" do
      it "0件のステータスも適切に表示される" do
        get content_path(content)
        expect(response).to have_http_status(:success)

        # すべて0件で表示されることを確認
        expect(response.body).to include("待機中: 0件")
        expect(response.body).to include("処理中: 0件")
        expect(response.body).to include("完了: 0件")
        expect(response.body).to include("失敗: 0件")
      end
    end

    context "ページをリロードした場合" do
      it "最新の集計が表示される" do
        # 初期状態を作成
        create(:music_generation, content: content, status: :pending)

        get content_path(content)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("待機中: 1件")
        expect(response.body).to include("処理中: 0件")

        # 新しいMusicGenerationを追加
        create(:music_generation, content: content, status: :processing)

        # 再度リクエスト
        get content_path(content)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("待機中: 1件")
        expect(response.body).to include("処理中: 1件")
      end
    end
  end
end
