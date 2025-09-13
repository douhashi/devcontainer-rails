require 'rails_helper'

RSpec.describe "MusicGenerationCard", type: :system, js: true, playwright: true do
  describe "preview pages" do
    it "displays completed generation with tracks" do
      visit "/rails/view_components/music_generation_card/completed_with_tracks"

      expect(page).to have_content("生成リクエスト #1")
      expect(page).to have_content("Mellow Beat #1")
      expect(page).to have_content("Mellow Beat #2")
      expect(page).to have_button("削除")
    end

    it "displays processing generation" do
      visit "/rails/view_components/music_generation_card/processing"

      expect(page).to have_content("生成リクエスト #2")
      expect(page).to have_content("音楽を生成中です...")
    end

    it "displays pending generation" do
      visit "/rails/view_components/music_generation_card/pending"

      expect(page).to have_content("生成リクエスト #3")
      expect(page).to have_content("音楽生成の開始を待っています...")
      expect(page).to have_button("削除")
    end

    it "displays failed generation" do
      visit "/rails/view_components/music_generation_card/failed"

      expect(page).to have_content("生成リクエスト #4")
      expect(page).to have_content("生成中にエラーが発生しました")
      expect(page).to have_button("削除")
    end
  end
end
