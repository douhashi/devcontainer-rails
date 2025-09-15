require 'rails_helper'

RSpec.describe "ArtworkMetadata", type: :system do
  let(:content) { create(:content) }

  before do
    driven_by(:rack_test)
    I18n.locale = :ja
  end

  describe "アートワークメタデータの管理" do
    context "アートワークメタデータが存在しない場合" do
      it "新規作成フォームが表示される" do
        visit content_path(content)

        within(".artwork-metadata-section") do
          expect(page).to have_content("アートワークメタデータ")
          expect(page).to have_field("ポジティブプロンプト")
          expect(page).to have_field("ネガティブプロンプト")
          expect(page).to have_button("アートワークメタデータを作成")
        end
      end

      it "アートワークメタデータを作成できる" do
        visit content_path(content)

        within(".artwork-metadata-section") do
          fill_in "ポジティブプロンプト", with: "beautiful landscape, digital art"
          fill_in "ネガティブプロンプト", with: "blurry, low quality"
          click_button "アートワークメタデータを作成"
        end

        expect(page).to have_content("beautiful landscape, digital art")
        expect(page).to have_content("blurry, low quality")
        expect(page).to have_button("コピー", count: 2)
      end

      it "バリデーションエラーが表示される" do
        visit content_path(content)

        within(".artwork-metadata-section") do
          # 空のフォームを送信
          click_button "アートワークメタデータを作成"
        end

        expect(page).to have_content("ポジティブプロンプトを入力してください")
        expect(page).to have_content("ネガティブプロンプトを入力してください")
      end
    end

    context "アートワークメタデータが存在する場合" do
      let!(:artwork_metadata) { create(:artwork_metadata, content: content) }

      it "アートワークメタデータが表示される" do
        visit content_path(content)

        within(".artwork-metadata-section") do
          expect(page).to have_content(artwork_metadata.positive_prompt)
          expect(page).to have_content(artwork_metadata.negative_prompt)
          expect(page).to have_button("コピー", count: 2)
        end
      end

      xit "編集モーダルを開いて更新できる" do
        # JavaScript required for modal functionality
        visit content_path(content)

        within(".artwork-metadata-section") do
          find('a[title="アートワークメタデータを編集"]').click
        end

        within("#artwork-metadata-edit-modal-#{artwork_metadata.id}") do
          fill_in "ポジティブプロンプト", with: "updated beautiful scenery"
          fill_in "ネガティブプロンプト", with: "updated noise"
          click_button "アートワークメタデータを更新"
        end

        expect(page).to have_content("updated beautiful scenery")
        expect(page).to have_content("updated noise")
      end

      xit "アートワークメタデータを削除できる" do
        # JavaScript required for confirm dialog
        visit content_path(content)

        within(".artwork-metadata-section") do
          accept_confirm("アートワークメタデータを削除しますか？") do
            find('button[title="アートワークメタデータを削除"]').click
          end
        end

        expect(page).to have_field("ポジティブプロンプト")
        expect(page).to have_field("ネガティブプロンプト")
        expect(page).to have_button("アートワークメタデータを作成")
      end

      xit "クリップボードにコピーできる" do
        # JavaScript required for clipboard functionality
        visit content_path(content)

        within(".artwork-metadata-section") do
          # ポジティブプロンプトをコピー
          first('button[title="クリップボードにコピー"]').click
          expect(page).to have_content("コピー済み")

          # 少し待ってから次のコピー
          sleep 2

          # ネガティブプロンプトをコピー
          all('button[title="クリップボードにコピー"]')[1].click
          expect(page).to have_content("コピー済み")
        end
      end
    end
  end
end
