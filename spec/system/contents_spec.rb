require "rails_helper"

RSpec.describe "Contents", type: :system do
  let(:user) { create(:user) }
  let(:content) { create(:content, duration_min: 10) }

  before do
    login_as(user, scope: :user)
  end

  describe "コンテンツ詳細画面" do
    context "音楽生成ステータス集計表示" do
      before do
        # 各ステータスのMusicGenerationを作成
        create_list(:music_generation, 2, content: content, status: :pending)
        create_list(:music_generation, 3, content: content, status: :processing)
        create_list(:music_generation, 4, content: content, status: :completed)
        create_list(:music_generation, 1, content: content, status: :failed)
      end

      it "ステータス集計が表示される" do
        visit content_path(content)

        within ".music-generations-section" do
          # ステータス集計が表示されることを確認
          expect(page).to have_css(".music-generation-status-summary")

          # 各ステータスの件数が表示されることを確認
          expect(page).to have_text("待機中: 2件")
          expect(page).to have_text("処理中: 3件")
          expect(page).to have_text("完了: 4件")
          expect(page).to have_text("失敗: 1件")
        end
      end

      it "ステータスごとに適切な色分けがされている" do
        visit content_path(content)

        within ".music-generation-status-summary" do
          # 各ステータスが適切な色クラスを持つことを確認
          expect(page).to have_css(".text-gray-500", text: /待機中/)
          expect(page).to have_css(".text-yellow-600", text: /処理中/)
          expect(page).to have_css(".text-green-600", text: /完了/)
          expect(page).to have_css(".text-red-600", text: /失敗/)
        end
      end
    end

    context "MusicGenerationが存在しない場合" do
      it "0件のステータスも適切に表示される" do
        visit content_path(content)

        within ".music-generations-section" do
          expect(page).to have_css(".music-generation-status-summary")

          # すべて0件で表示されることを確認
          expect(page).to have_text("待機中: 0件")
          expect(page).to have_text("処理中: 0件")
          expect(page).to have_text("完了: 0件")
          expect(page).to have_text("失敗: 0件")
        end
      end
    end

    context "ページをリロードした場合" do
      it "最新の集計が表示される" do
        # 初期状態を作成
        create(:music_generation, content: content, status: :pending)

        visit content_path(content)

        within ".music-generation-status-summary" do
          expect(page).to have_text("待機中: 1件")
          expect(page).to have_text("処理中: 0件")
        end

        # 新しいMusicGenerationを追加
        create(:music_generation, content: content, status: :processing)

        # ページをリロード
        visit content_path(content)

        within ".music-generation-status-summary" do
          expect(page).to have_text("待機中: 1件")
          expect(page).to have_text("処理中: 1件")
        end
      end
    end

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
  end
end
