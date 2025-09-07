require 'rails_helper'

RSpec.describe "Contents", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end


  describe "Delete confirmation", js: true do
    let!(:content) { create(:content, theme: "削除するコンテンツ") }

    it "shows confirmation dialog and deletes content when confirmed" do
      visit content_path(content)

      accept_confirm("本当に削除しますか？") do
        click_link "削除"
      end

      expect(page).to have_current_path(contents_path)
      expect(page).to have_text("Content was successfully destroyed")
      expect(Content.exists?(content.id)).to be false
    end

    it "cancels deletion when user declines" do
      visit content_path(content)

      dismiss_confirm do
        click_link "削除"
      end

      expect(page).to have_current_path(content_path(content))
      expect(Content.exists?(content.id)).to be true
    end
  end

  describe "Flash message auto-hide", js: true do
    it "automatically hides flash message after 5 seconds" do
      create(:content, theme: "テストコンテンツ")
      visit contents_path

      click_link "新規作成"
      fill_in "content_theme", with: "新しいコンテンツ"
      fill_in "content_duration", with: "3"
      fill_in "content_audio_prompt", with: "リラックスできるローファイBGM"
      click_button "Create Content"

      expect(page).to have_text("Content was successfully created")

      # 5秒待つとメッセージが消える
      sleep 6
      expect(page).not_to have_text("Content was successfully created")
    end

    it "allows manual closing of flash message" do
      create(:content, theme: "テストコンテンツ")
      visit contents_path

      click_link "新規作成"
      fill_in "content_theme", with: "新しいコンテンツ"
      fill_in "content_duration", with: "3"
      fill_in "content_audio_prompt", with: "リラックスできるローファイBGM"
      click_button "Create Content"

      expect(page).to have_text("Content was successfully created")

      # 手動でクローズボタンをクリック
      within("[data-controller='flash-message']") do
        find("button").click
      end

      expect(page).not_to have_text("Content was successfully created")
    end
  end

  describe "Responsive layout", js: true do
    before do
      3.times { |i| create(:content, theme: "コンテンツ#{i + 1}") }
    end

    it "adjusts grid layout for mobile" do
      visit contents_path

      # デスクトップサイズ
      page.driver.browser.manage.window.resize_to(1200, 800)
      expect(page).to have_css(".lg\\:grid-cols-3")

      # モバイルサイズ
      page.driver.browser.manage.window.resize_to(375, 667)
      expect(page).to have_css(".grid-cols-1")
    end
  end
end
