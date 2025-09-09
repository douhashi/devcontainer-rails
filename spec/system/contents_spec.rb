require 'rails_helper'

RSpec.describe "Contents Flash Message Controller", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "Flash message auto-hide", js: true do
    it "automatically hides flash message after 5 seconds" do
      create(:content, theme: "テストコンテンツ")
      visit contents_path

      click_link "新規作成"
      fill_in "content_theme", with: "新しいコンテンツ"
      fill_in "content_duration_min", with: "3"
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
      fill_in "content_duration_min", with: "3"
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
end
