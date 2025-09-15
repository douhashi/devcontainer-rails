require "rails_helper"

RSpec.describe "Contents", type: :system, playwright: true do
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
  end
end
