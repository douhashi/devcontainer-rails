# frozen_string_literal: true

require "rails_helper"

describe "single_track_generation_button component" do
  it "default preview" do
    visit("/rails/view_components/single_track_generation_button/default")

    expect(page).to have_button("音楽生成（2曲）")
  end

  it "with_processing_track preview" do
    visit("/rails/view_components/single_track_generation_button/with_processing_track")

    expect(page).to have_button("生成中...", disabled: true)
    expect(page).to have_text("BGM生成処理中です")
  end
end
