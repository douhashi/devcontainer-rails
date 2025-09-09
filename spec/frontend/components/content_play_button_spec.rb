# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentPlayButton::Component, type: :component do
  let(:content) { create(:content) }
  let(:audio) { create(:audio, :completed, content: content) }
  let(:options) { { content_record: content } }
  let(:component) { ContentPlayButton::Component.new(**options) }

  it "renders" do
    allow(audio).to receive_message_chain(:audio, :url).and_return('/test/audio.mp3')
    allow(audio).to receive_message_chain(:audio, :present?).and_return(true)
    content.audio = audio

    result = render_inline(component)

    expect(result.css("button")).to be_present
  end
end
