# frozen_string_literal: true

require "rails_helper"

describe EmptyTrackRow::Component do
  include ViewComponent::TestHelpers
  let(:music_generation) { create(:music_generation) }
  let(:component) { EmptyTrackRow::Component.new(music_generation: music_generation) }

  it "renders" do
    render_inline(component)

    expect(page).to have_css "tr"
  end
end
