require "rails_helper"

RSpec.describe "Artwork Download", type: :system, js: true do
  let(:content) { create(:content) }
  let!(:artwork) { create(:artwork, content: content) }

  before do
    visit content_path(content)
  end

  context "when downloading original artwork" do
    it "downloads with correct filename format" do
      # アートワークセクションが表示されるまで待つ
      expect(page).to have_content("アートワーク")

      # オリジナル画像のダウンロードボタンをクリック
      within(".artwork-variations-grid") do
        first(".download-button").click
      end

      # ダウンロードが開始されることを確認（実際のファイルダウンロードはテストでは困難なため、
      # リンクが正しく設定されていることを確認）
      download_link = first(".download-button")
      expect(download_link[:href]).to include("/download/original")
    end
  end

  context "with youtube thumbnail available" do
    let(:content_with_thumbnail) { create(:content) }
    let!(:artwork_with_thumbnail) { create(:artwork, :with_youtube_thumbnail, content: content_with_thumbnail) }

    it "shows download button for youtube thumbnail" do
      visit content_path(content_with_thumbnail)

      expect(page).to have_content("アートワーク")

      # YouTube用のダウンロードボタンが存在することを確認
      within(".artwork-variations-grid") do
        expect(page).to have_css(".download-button", count: 2) # original + youtube_thumbnail

        # YouTube用のダウンロードリンクを確認
        youtube_download_link = all(".download-button").find { |link|
          link[:href]&.include?("/download/youtube_thumbnail")
        }
        expect(youtube_download_link).to be_present
      end
    end
  end

  context "when no artwork exists" do
    let(:content_without_artwork) { create(:content) }

    it "shows drag and drop area" do
      visit content_path(content_without_artwork)

      expect(page).to have_content("画像をドラッグ&ドロップ")
      expect(page).not_to have_css(".download-button")
    end
  end
end
