require 'rails_helper'

RSpec.describe "Artwork Image Switcher", type: :system do
  include_context "ログイン済み"

  let(:content) { create(:content) }
  let(:artwork) { create(:artwork, content: content) }

  describe "基本機能" do
    it "アートワークがある場合、ギャラリーが表示される" do
      content.update!(artwork: artwork)
      visit content_path(content)

      # Turbo Frameが正しく設定されていることを確認
      expect(page).to have_css("turbo-frame[id='artwork_#{content.id}']")

      # 画像が表示されることを確認
      expect(page).to have_css('img[alt="アートワーク"]')

      # Stimulus コントローラーが設定されていることを確認
      expect(page).to have_css('[data-controller*="artwork-switcher"]')
    end

    it "オリジナル画像のサムネイルが表示される" do
      content.update!(artwork: artwork)
      visit content_path(content)

      # ギャラリーが表示されることを確認
      expect(page).to have_css('.artwork-gallery')
      expect(page).to have_css('[data-image-type="original"]')
      expect(page).to have_text('オリジナル')
    end

    it "サムネイルがクリック可能な構造を持っている" do
      content.update!(artwork: artwork)
      visit content_path(content)

      # サムネイルの属性を確認
      within '.artwork-gallery' do
        expect(page).to have_css('[role="button"]')
        expect(page).to have_css('[tabindex="0"]')
        expect(page).to have_css('[data-action*="click->artwork-switcher#switchImage"]')
      end
    end
  end

  describe "アクセシビリティ" do
    it "適切なARIA属性が設定されている" do
      content.update!(artwork: artwork)
      visit content_path(content)

      expect(page).to have_css('[aria-label*="オリジナル画像に切り替え"]')
    end
  end

  describe "アートワーク未設定時" do
    it "ギャラリーが表示されない" do
      visit content_path(content)

      expect(page).not_to have_css('.artwork-gallery')
      expect(page).to have_text("画像をドラッグ&ドロップ")
    end
  end
end
