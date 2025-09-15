require "rails_helper"

RSpec.describe "Artwork UI Improvements", type: :system do
  let(:content) { create(:content, id: 1) }
  let!(:artwork) { create(:artwork, content: content) }

  before do
    # Mock the image URL and metadata for testing
    allow_any_instance_of(Artwork).to receive(:image).and_return(
      double(
        url: "/test_image.jpg",
        present?: true,
        metadata: { "width" => 1920, "height" => 1080 },
        size: 2621440,
        original_filename: "test_image.jpg"
      )
    )
  end

  describe "Artwork grid display" do
    it "does not display file size information" do
      visit content_path(content)

      within(".artwork-section") do
        # ファイルサイズの表示がないことを確認
        expect(page).not_to have_text("ファイルサイズ")

        # サイズ（画像解像度）は表示される
        expect(page).to have_text("サイズ:")
        expect(page).to have_text("1920x1080")
      end
    end
  end

  describe "Download filename format" do
    it "uses systematic naming convention for original image" do
      visit content_path(content)

      within(".artwork-section") do
        # ダウンロードリンクが正しいパスを持つことを確認
        download_link = find("a.download-button", match: :first)
        href = download_link[:href]

        # 新しいダウンロードパス形式を確認
        expect(href).to include("/download/original")
      end
    end

    context "with different content IDs" do
      let(:content) { create(:content, id: 999) }

      it "pads content ID with zeros to 4 digits" do
        visit content_path(content)

        within(".artwork-section") do
          download_link = find("a.download-button", match: :first)
          href = download_link[:href]

          expect(href).to include("/contents/999/artworks/")
          expect(href).to include("/download/original")
        end
      end
    end

    context "with content ID over 10000" do
      let(:content) { create(:content, id: 10001) }

      it "does not pad IDs over 4 digits" do
        visit content_path(content)

        within(".artwork-section") do
          download_link = find("a.download-button", match: :first)
          href = download_link[:href]

          expect(href).to include("/contents/10001/artworks/")
          expect(href).to include("/download/original")
        end
      end
    end
  end

  describe "Delete button display" do
    it "shows delete button as icon only", js: true do
      visit content_path(content)

      within(".artwork-section") do
        delete_button = find("button[aria-label='アートワークを削除']")

        # アイコンのみで表示されていることを確認（テキストなし）
        expect(delete_button).not_to have_text("アートワークを削除")

        # Font Awesomeアイコンが存在することを確認
        expect(delete_button).to have_css("i.fa-trash", visible: :all)

        # title属性でツールチップが設定されていることを確認
        expect(delete_button[:title]).to eq("アートワークを削除")

        # aria-label属性でアクセシビリティが確保されていることを確認
        expect(delete_button[:"aria-label"]).to eq("アートワークを削除")
      end
    end

    it "maintains delete functionality with confirmation dialog", js: true do
      visit content_path(content)

      within(".artwork-section") do
        # 削除ボタンをクリック
        accept_confirm("アートワークを削除しますか？") do
          find("button[aria-label='アートワークを削除']").click
        end

        # 削除後のリダイレクトを待つ
        expect(page).to have_current_path(content_path(content))
      end
    end
  end

  describe "Button styling consistency" do
    it "uses consistent styling with other icon buttons", js: true do
      visit content_path(content)

      # アートワーク削除ボタンのスタイルを取得
      artwork_delete_button = find(".artwork-section button[aria-label='アートワークを削除']")

      # 作品概要の削除ボタンのスタイルを取得
      content_delete_button = find("a[aria-label='削除']")

      # 両方がFont Awesomeアイコンのみのボタンであることを確認
      expect(artwork_delete_button).to have_css("i.fa-trash", visible: :all)
      expect(content_delete_button).to have_css("i.fa-trash", visible: :all)

      # テキストラベルがないことを確認
      expect(artwork_delete_button.text.strip).to eq("")
      expect(content_delete_button.text.strip).to eq("")
    end
  end
end
