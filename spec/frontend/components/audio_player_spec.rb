# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioPlayer::Component, type: :component do
  let(:content) { create(:content) }
  let(:track_with_audio) { create(:track, :completed, content: content) }
  let(:track_without_audio) { create(:track, :completed, content: content) }
  let(:processing_track) { create(:track, :processing, content: content) }

  describe "with track having audio" do
    let(:component) { AudioPlayer::Component.new(track: track_with_audio) }

    before do
      allow(track_with_audio).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    subject { rendered_content }

    it "renders audio player" do
      render_inline(component)

      is_expected.to have_css('div[data-controller="audio-player"]')
      is_expected.to have_css('audio[data-audio-player-target="player"]')
      is_expected.to have_css('audio[data-audio-url="https://example.com/test.mp3"]')
    end

    it "includes table-optimized CSS classes" do
      render_inline(component)

      is_expected.to have_css('div.max-w-xs.w-full')
    end
  end

  describe "with track without audio" do
    let(:component) { AudioPlayer::Component.new(track: track_without_audio) }

    before do
      allow(track_without_audio).to receive(:audio).and_return(double(present?: false))
    end

    it "does not render when audio is not present" do
      result = render_inline(component)

      expect(result.to_html.strip).to be_empty
    end
  end

  describe "with processing track" do
    let(:component) { AudioPlayer::Component.new(track: processing_track) }

    before do
      allow(processing_track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    it "does not render when track is not completed" do
      result = render_inline(component)

      expect(result.to_html.strip).to be_empty
    end
  end

  describe "with custom css_class" do
    let(:component) { AudioPlayer::Component.new(track: track_with_audio, css_class: "custom-class") }

    before do
      allow(track_with_audio).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    subject { rendered_content }

    it "includes custom CSS class" do
      render_inline(component)

      is_expected.to have_css('div.custom-class')
    end
  end
end
