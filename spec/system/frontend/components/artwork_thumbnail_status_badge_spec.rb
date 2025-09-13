# frozen_string_literal: true

require "rails_helper"

describe "artwork_thumbnail_status_badge component" do
  it "default preview" do
    visit("/rails/view_components/artwork_thumbnail_status_badge/default")

    # is_expected.to have_text "Hello!"
    # click_on "Click me"
    # is_expected.to have_text "Good-bye!"
  end
end
