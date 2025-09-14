# frozen_string_literal: true

require "rails_helper"

RSpec.describe InlineAudioPlayer::Component, type: :component do
  let(:track) { create(:track, :completed, :with_audio) }
  let(:options) { { track: track } }
  let(:component) { InlineAudioPlayer::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end
