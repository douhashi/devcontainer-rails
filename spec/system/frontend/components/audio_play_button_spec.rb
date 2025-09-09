# frozen_string_literal: true

require "rails_helper"

describe "audio_play_button component" do
  it "default preview" do
    visit("/rails/view_components/audio_play_button/default")

    # is_expected.to have_text "Hello!"
    # click_on "Click me"
    # is_expected.to have_text "Good-bye!"
  end
end
