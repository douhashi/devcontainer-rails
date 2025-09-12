# frozen_string_literal: true

require "rails_helper"

describe "music_generation_status_summary component" do
  it "default preview" do
    visit("/rails/view_components/music_generation_status_summary/default")

    # is_expected.to have_text "Hello!"
    # click_on "Click me"
    # is_expected.to have_text "Good-bye!"
  end
end
