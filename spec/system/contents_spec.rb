require "rails_helper"

RSpec.describe "Contents", type: :system do
  let(:content) { create(:content, duration_min: 10) }


  describe "コンテンツ詳細画面" do
    context "一覧に戻るリンクのアイコン化", js: true do
      it "アイコンリンクが表示され、一覧画面に遷移できる" do
        visit content_path(content)

        # アイコンが表示されていることを確認（ページ上部の最初のリンク）
        within first(".mb-6") do
          expect(page).to have_css("a[href='#{contents_path}'] i.fa-arrow-left")

          # aria-labelが設定されていることを確認
          expect(page).to have_css("i[aria-label='一覧に戻る']")

          # テキスト「一覧に戻る」が表示されていないことを確認
          expect(page).not_to have_text("← 一覧に戻る")

          # アイコンをクリックして一覧画面に遷移
          back_link = find("a[href='#{contents_path}']")
          back_link.click
        end

        # 一覧画面に遷移したことを確認
        # 画面遷移を待つ
        expect(page).to have_current_path(contents_path, wait: 5)
      end

      it "アイコンリンクにホバー効果がある" do
        visit content_path(content)

        # リンクがホバー効果のクラスを持つことを確認（ページ上部の最初のリンク）
        within first(".mb-6") do
          back_link = find("a[href='#{contents_path}']")
          expect(back_link[:class]).to include("text-blue-400")
          expect(back_link[:class]).to include("hover:text-blue-300")
        end
      end
    end

    context "動画生成完了後の表示", js: true do
      let!(:artwork) { create(:artwork, content: content) }
      let!(:audio) { create(:audio, content: content, status: :completed) }

      context "動画が生成完了している場合" do
        let!(:video) do
          video = create(:video,
            content: content,
            status: :completed,
            resolution: "1920x1080",
            file_size: 5242880,
            duration_seconds: 600
          )
          # ビデオファイルのURLをモック
          allow(video).to receive_message_chain(:video, :url).and_return("https://example.com/video.mp4")
          video
        end

        before do
          # Videoインスタンスを返すようにモック
          allow(content).to receive(:video).and_return(video)
        end

        it "エラーなくコンテンツ詳細ページが表示される" do
          visit content_path(content)

          # ページが正常に表示されることを確認
          expect(page).to have_current_path(content_path(content))
          expect(page).not_to have_content("NoMethodError")
          expect(page).not_to have_content("private method")

          # 動画セクションが表示されていることを確認
          expect(page).to have_content("動画生成")

          # ステータスバッジが表示されていることを確認
          expect(page).to have_css(".bg-green-100", text: "完了")

          # 削除ボタンが表示されていることを確認（完了時は削除ボタンが表示）
          expect(page).to have_css("button[data-turbo-confirm]")
        end

        it "動画の技術仕様が表示される" do
          visit content_path(content)

          # 動画生成セクションが存在することを確認
          within(".video-generation-section") do
            # 解像度が表示されていることを確認
            expect(page).to have_content("1920x1080")

            # ファイルサイズが表示されていることを確認（5.0 MB）
            expect(page).to have_content("5.0 MB")

            # 再生時間が表示されていることを確認（10:00）
            expect(page).to have_content("10:00")

            # 技術仕様が表示されていることを確認
            expect(page).to have_content("H.264 (libx264)")
            expect(page).to have_content("AAC (192kbps, 48kHz)")
            expect(page).to have_content("30fps")
          end
        end
      end

      context "動画が処理中の場合" do
        let!(:video) { create(:video, content: content, status: :processing) }

        it "エラーなくコンテンツ詳細ページが表示される" do
          visit content_path(content)

          # ページが正常に表示されることを確認
          expect(page).to have_current_path(content_path(content))
          expect(page).not_to have_content("NoMethodError")

          # 処理中のステータスが表示されていることを確認
          expect(page).to have_content("動画生成")
          expect(page).to have_css(".bg-blue-100", text: "作成中")

          # 作成中ボタンが表示されていることを確認
          expect(page).to have_button("作成中", disabled: true)
        end
      end

      context "動画が存在しない場合" do
        it "エラーなくコンテンツ詳細ページが表示され、生成ボタンが表示される" do
          visit content_path(content)

          # ページが正常に表示されることを確認
          expect(page).to have_current_path(content_path(content))
          expect(page).not_to have_content("NoMethodError")

          # 動画生成ボタンが表示されていることを確認
          expect(page).to have_button("動画を生成")
        end
      end

      context "動画生成が失敗した場合" do
        let!(:video) { create(:video, content: content, status: :failed, error_message: "エンコーディングエラー") }

        it "エラーメッセージとともに詳細ページが表示される" do
          visit content_path(content)

          # ページが正常に表示されることを確認
          expect(page).to have_current_path(content_path(content))
          expect(page).not_to have_content("NoMethodError")

          # 失敗ステータスが表示されていることを確認
          expect(page).to have_css(".bg-red-100", text: "失敗")

          # エラーメッセージが表示されていることを確認
          within(".video-generation-section") do
            expect(page).to have_content("エラー: エンコーディングエラー")
          end

          # 削除ボタンが表示されていることを確認（失敗した動画を削除可能）
          expect(page).to have_button("削除")
        end
      end
    end
  end
end
