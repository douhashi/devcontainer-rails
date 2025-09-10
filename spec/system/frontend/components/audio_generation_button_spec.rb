# frozen_string_literal: true

require "rails_helper"

describe "audio_generation_button component", type: :system do
  context "when viewing default preview" do
    before do
      visit("/rails/view_components/audio_generation_button/default")
    end

    it "shows generate button" do
      expect(page).to have_button("音源を生成")
    end
  end

  context "when audio is completed" do
    before do
      visit("/rails/view_components/audio_generation_button/completed")
    end

    it "shows delete button that is enabled" do
      expect(page).to have_button("削除", disabled: false)
    end
  end

  context "when audio is processing" do
    before do
      visit("/rails/view_components/audio_generation_button/processing")
    end

    it "shows processing button that is disabled" do
      expect(page).to have_button("作成中", disabled: true)
    end
  end

  context "when audio is failed" do
    before do
      visit("/rails/view_components/audio_generation_button/failed")
    end

    it "shows delete button that is enabled" do
      expect(page).to have_button("削除", disabled: false)
    end
  end

  context "when audio is pending" do
    before do
      visit("/rails/view_components/audio_generation_button/pending")
    end

    it "shows pending button that is disabled" do
      expect(page).to have_button("作成中", disabled: true)
    end
  end
end
