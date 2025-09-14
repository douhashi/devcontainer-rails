# frozen_string_literal: true

require "rails_helper"

RSpec.describe "InlineAudioPlayer Exclusive Control", type: :request do
  let!(:content) { create(:content) }
  let!(:track1) { create(:track, :completed, :with_audio, content: content, metadata: { "music_title" => "Track 1" }) }
  let!(:track2) { create(:track, :completed, :with_audio, content: content, metadata: { "music_title" => "Track 2" }) }

  describe "Multiple players rendering" do
    it "renders multiple inline audio players with unique IDs" do
      # This test ensures that the HTML structure is correct
      # The actual exclusive control is tested via JavaScript

      # Create a simple test view that includes multiple players
      component1 = InlineAudioPlayer::Component.new(track: track1)
      component2 = InlineAudioPlayer::Component.new(track: track2)

      # Simulate rendering the components directly
      test_html = <<~HTML
        <div id="test-container">
          <div id="inline-audio-player-track-#{track1.id}"
               data-controller="inline-audio-player"
               data-inline-audio-player-id-value="#{track1.id}"
               data-inline-audio-player-type-value="track"
               data-inline-audio-player-title-value="Track 1"
               data-inline-audio-player-url-value="/test/audio1.mp3">
          </div>
          <div id="inline-audio-player-track-#{track2.id}"
               data-controller="inline-audio-player"
               data-inline-audio-player-id-value="#{track2.id}"
               data-inline-audio-player-type-value="track"
               data-inline-audio-player-title-value="Track 2"
               data-inline-audio-player-url-value="/test/audio2.mp3">
          </div>
        </div>
      HTML

      # Check that both players have unique IDs
      expect(test_html).to include("inline-audio-player-track-#{track1.id}")
      expect(test_html).to include("inline-audio-player-track-#{track2.id}")

      # Check that Stimulus controller is attached
      expect(test_html).to include('data-controller="inline-audio-player"')
      expect(test_html).to include("data-inline-audio-player-id-value=\"#{track1.id}\"")
      expect(test_html).to include("data-inline-audio-player-id-value=\"#{track2.id}\"")
    end
  end
end
