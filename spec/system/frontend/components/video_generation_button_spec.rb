# frozen_string_literal: true

require "rails_helper"

describe "video_generation_button component", type: :system do
  context "when viewing default preview" do
    before do
      visit("/rails/view_components/video_generation_button/default")
    end

    it "shows video generation button" do
      expect(page).to have_button("動画を生成")
    end
  end

  context "when video is completed" do
    before do
      visit("/rails/view_components/video_generation_button/completed")
    end

    it "shows download link and delete button" do
      expect(page).to have_link("ダウンロード")
      expect(page).to have_button("削除")
    end
  end

  context "when video is processing" do
    before do
      visit("/rails/view_components/video_generation_button/processing")
    end

    it "shows processing button that is disabled" do
      expect(page).to have_button("作成中", disabled: true)
    end
  end

  context "when video is failed" do
    before do
      visit("/rails/view_components/video_generation_button/failed")
    end

    it "shows failed message and delete button" do
      expect(page).to have_content("生成失敗")
      expect(page).to have_button("削除", disabled: false)
    end
  end
end
