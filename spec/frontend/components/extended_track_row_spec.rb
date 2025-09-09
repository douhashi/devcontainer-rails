# frozen_string_literal: true

require "rails_helper"

describe ExtendedTrackRow::Component do
  include ViewComponent::TestHelpers
  let(:track) { create(:track) }
  let(:music_generation) { create(:music_generation) }
  let(:component) do
    ExtendedTrackRow::Component.new(
      track: track,
      music_generation: music_generation,
      is_group_start: true,
      group_size: 1
    )
  end

  it "renders" do
    render_inline(component)

    expect(page).to have_css "tr"
  end
end
