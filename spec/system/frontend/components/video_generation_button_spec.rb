# frozen_string_literal: true

require "rails_helper"

describe "video_generation_button component", type: :system do
  let(:content) { create(:content) }

  before do
    create(:audio, :completed, content: content)
    create(:artwork, content: content)
  end

  context "when video is completed" do
    let!(:video) { create(:video, :completed, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is enabled" do
      within(".video-generation-section") do
        expect(page).to have_button("削除", disabled: false)
        expect(page).to have_css("button", text: "削除")
      end
    end

    it "shows confirmation dialog when delete button is clicked", js: true do
      within(".video-generation-section") do
        accept_confirm do
          click_button "削除"
        end
      end
      expect(page).to have_content("動画が削除されました")
    end
  end

  context "when video is failed" do
    let!(:video) { create(:video, :failed, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is enabled" do
      within(".video-generation-section") do
        expect(page).to have_button("削除", disabled: false)
      end
    end
  end

  context "when video is processing" do
    let!(:video) { create(:video, :processing, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is disabled" do
      within(".video-generation-section") do
        expect(page).to have_button("削除", disabled: true)
      end
    end

    it "has disabled appearance" do
      within(".video-generation-section") do
        delete_button = find("button", text: "削除")
        expect(delete_button[:class]).to include("cursor-not-allowed")
        expect(delete_button[:class]).to include("opacity-50")
      end
    end
  end

  context "when video is pending" do
    let!(:video) { create(:video, :pending, content: content) }

    before do
      visit content_path(content)
    end

    it "does not show delete button" do
      within(".video-generation-section") do
        expect(page).not_to have_button("削除")
      end
    end
  end

  context "when video does not exist" do
    before do
      visit content_path(content)
    end

    it "does not show delete button" do
      within(".video-generation-section") do
        expect(page).not_to have_button("削除")
      end
    end
  end
end
