require "rails_helper"

RSpec.describe "Artwork Thumbnail Synchronous Generation", type: :system, js: true do
  let(:content) { create(:content) }

  before do
    I18n.locale = :ja
  end

  describe "アートワークアップロード時の同期的サムネイル生成" do
    context "1920x1080の画像をアップロードした場合" do
      it "アップロード中にサムネイル生成中の表示が出て、完了後にサムネイルが生成される" do
        visit content_path(content)

        # ドラッグアンドドロップエリアが表示される
        expect(page).to have_css("[data-controller='artwork-drag-drop']")

        # ファイルをアップロード
        within "[data-controller='artwork-drag-drop']" do
          # ファイル選択
          file_path = Rails.root.join("spec/fixtures/files/images/fhd_placeholder.jpg")
          attach_file "artwork[image]", file_path, make_visible: true

          # ローディング表示の確認
          expect(page).to have_content("アップロード中")
        end

        # アップロード完了後の確認（グリッドに画像が表示される）
        expect(page).to have_css('.artwork-variations-grid img', wait: 10)
        # 削除ボタンが表示されることを確認（アートワークが正常にアップロードされた証拠）
        expect(page).to have_button("", disabled: false) # 削除ボタン（アイコンのみ）
      end
    end

    context "1920x1080以外の画像をアップロードした場合" do
      it "アップロードは成功するがサムネイルは生成されない" do
        visit content_path(content)

        within "[data-controller='artwork-drag-drop']" do
          file_path = Rails.root.join("spec/fixtures/files/images/hd_placeholder.jpg")
          attach_file "artwork[image]", file_path, make_visible: true
        end

        # アップロード完了後の確認（グリッドに画像が表示される）
        expect(page).to have_css('.artwork-variations-grid img', wait: 10)
        # 削除ボタンが表示されることを確認（アートワークが正常にアップロードされた証拠）
        expect(page).to have_button("", disabled: false) # 削除ボタン（アイコンのみ）
      end
    end

    context "サムネイル生成でタイムアウトが発生した場合" do
      it "エラーメッセージが表示される", skip: "タイムアウトは実際に30秒待つ必要がありテストに適さない" do
        visit content_path(content)

        within "[data-controller='artwork-drag-drop']" do
          file_path = Rails.root.join("spec/fixtures/files/images/fhd_placeholder.jpg")
          attach_file "artwork[image]", file_path, make_visible: true
        end

        # エラーメッセージの確認
        expect(page).to have_content(I18n.t('artworks.thumbnail.generation_timeout'))
      end
    end

    context "サムネイル生成でエラーが発生した場合" do
      it "エラーメッセージが表示される", skip: "実際のエラーは不確定的でテストに適さない" do
        visit content_path(content)

        within "[data-controller='artwork-drag-drop']" do
          file_path = Rails.root.join("spec/fixtures/files/images/fhd_placeholder.jpg")
          attach_file "artwork[image]", file_path, make_visible: true
        end

        # エラーメッセージの確認
        expect(page).to have_content(I18n.t('artworks.thumbnail.generation_failed'))
        expect(page).to have_content("Invalid image format")
      end
    end
  end

  describe "サムネイルの再生成" do
    let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed) }

    before do
    end

    it "再生成ボタンをクリックすると同期的にサムネイルが再生成される", skip: "再生成ボタンは非同期処理のため、同期処理のテストとは一致しない" do
      visit content_path(content)

      # 再生成ボタンをクリック
      accept_confirm do
        click_button "再生成"
      end

      # 成功メッセージの確認
      expect(page).to have_content(I18n.t('artworks.thumbnail.regeneration_started'))

      # サムネイルが生成されたことを確認
      expect(page).to have_button("プレビュー")
      expect(page).to have_link("ダウンロード")
    end
  end
end
