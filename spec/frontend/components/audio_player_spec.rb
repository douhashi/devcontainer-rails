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

    it "renders audio player with media-chrome components" do
      render_inline(component)

      is_expected.to have_css('div[data-controller="audio-player"]')
      is_expected.to have_css('media-controller[data-audio-player-target="player"]')
      is_expected.to have_css('media-controller[data-audio-url="https://example.com/test.mp3"]')
      is_expected.to have_css('media-control-bar')
      is_expected.to have_css('media-play-button')
      is_expected.to have_css('media-time-range')
      is_expected.to have_css('media-time-display')
      is_expected.to have_css('media-volume-range')
    end

    it "includes table-optimized CSS classes" do
      render_inline(component)

      is_expected.to have_css('div.max-w-md.w-full')
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

  describe "dark theme styling" do
    let(:component) { AudioPlayer::Component.new(track: track_with_audio) }

    before do
      allow(track_with_audio).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    subject { rendered_content }

    it "includes dark theme classes for media-chrome controls" do
      render_inline(component)

      # Check for dark theme specific classes
      is_expected.to have_css('media-controller[class*="bg-gray-800"]')
      is_expected.to have_css('media-control-bar[class*="bg-gray-800"]')
    end

    it "does not include white background classes" do
      render_inline(component)

      # Ensure no white background classes are present
      is_expected.not_to have_css('[class*="bg-white"]')
      is_expected.not_to have_css('[class*="bg-gray-100"]')
      is_expected.not_to have_css('[class*="bg-gray-200"]')
    end
  end

  describe "layout optimization" do
    let(:component) { AudioPlayer::Component.new(track: track_with_audio) }

    before do
      allow(track_with_audio).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    subject { rendered_content }

    it "includes optimized layout classes" do
      render_inline(component)

      # Check for layout optimization classes
      is_expected.to have_css('div[class*="max-w-"]') # Should have max-width constraint
      is_expected.to have_css('div[class*="w-full"]') # Should be full width within constraint
      is_expected.to have_css('div[class*="min-w-0"]') # Should allow shrinking
    end

    it "includes media-chrome controls" do
      render_inline(component)

      # Check for media-chrome specific controls
      is_expected.to have_css('media-time-range')
      is_expected.to have_css('media-volume-range')
      is_expected.to have_css('media-time-display')
    end

    it "includes control size optimizations" do
      render_inline(component)

      # Check for control size optimizations
      is_expected.to have_css('media-play-button')
      is_expected.to have_css('media-volume-range')
    end
  end
end
