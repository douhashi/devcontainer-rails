# frozen_string_literal: true

require "rails_helper"

describe "audio_generation_button component", type: :system do
  let(:content) { create(:content) }

  before do
    # Prerequisites for audio generation
    create(:artwork, content: content)
    create_list(:track, 3, :completed, content: content, duration_sec: 180)
  end

  context "when audio is completed" do
    let!(:audio) { create(:audio, :completed, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is enabled" do
      within(".audio-generation-section") do
        expect(page).to have_button("削除", disabled: false)
        expect(page).to have_css("button", text: "削除")
      end
    end
  end

  context "when audio is failed" do
    let!(:audio) { create(:audio, :failed, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is enabled" do
      within(".audio-generation-section") do
        expect(page).to have_button("削除", disabled: false)
      end
    end
  end

  context "when audio is processing" do
    let!(:audio) { create(:audio, :processing, content: content) }

    before do
      visit content_path(content)
    end

    it "shows delete button that is disabled" do
      within(".audio-generation-section") do
        expect(page).to have_button("削除", disabled: true)
      end
    end

    it "has disabled appearance" do
      within(".audio-generation-section") do
        delete_button = find("button", text: "削除")
        expect(delete_button[:class]).to include("cursor-not-allowed")
        expect(delete_button[:class]).to include("opacity-50")
      end
    end
  end

  context "when audio is pending" do
    let!(:audio) { create(:audio, :pending, content: content) }

    before do
      visit content_path(content)
    end

    it "does not show delete button" do
      within(".audio-generation-section") do
        expect(page).not_to have_button("削除")
      end
    end
  end

  context "when audio does not exist" do
    before do
      visit content_path(content)
    end

    it "does not show delete button" do
      within(".audio-generation-section") do
        expect(page).not_to have_button("削除")
      end
    end
  end
end
