# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unified Audio Play Integration", type: :system do
  describe "Track and Content audio play functionality" do
    let(:content) { create(:content, theme: "Test Content Theme") }

    context "when playing content audio" do
      let!(:audio) do
        audio = create(:audio, :completed, content: content)
        # Create a temporary audio file for testing
        tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
        tempfile.write("dummy audio content")
        tempfile.rewind

        audio.audio = tempfile
        audio.save!
        tempfile.close
        tempfile.unlink
        audio
      end

      before do
        visit content_path(content)
      end

      it "plays content audio using unified system", js: true do
        # Look for the unified AudioPlayButton component
        expect(page).to have_css('button[data-controller="audio-play-button"]')
        expect(page).to have_css('button[data-audio-play-button-type-value="content"]')

        # Click the play button
        find('button[data-controller="audio-play-button"]').click

        # Wait for floating player to appear
        expect(page).to have_css('.floating-audio-player', visible: true)

        # Check that the floating player shows the correct content
        within('.floating-audio-player') do
          expect(page).to have_content(content.theme)
        end
      end
    end

    context "when playing track audio" do
      let(:track) do
        track = create(:track, :completed, content: content)
        track.update(metadata: { music_title: 'Test Track Title' })
        track
      end

      before do
        # Create a temporary audio file for testing
        tempfile = Tempfile.new([ 'test_track_audio', '.mp3' ])
        tempfile.write("dummy track audio content")
        tempfile.rewind

        track.audio = tempfile
        track.save!
        tempfile.close
        tempfile.unlink

        visit content_path(content)
      end

      it "plays track audio using unified system", js: true do
        # Look for the unified AudioPlayButton component for track
        expect(page).to have_css('button[data-audio-play-button-type-value="track"]')

        # Click the play button
        find('button[data-audio-play-button-type-value="track"]').click

        # Wait for floating player to appear
        expect(page).to have_css('.floating-audio-player', visible: true)

        # Check that the floating player shows the correct track title
        within('.floating-audio-player') do
          expect(page).to have_content('Test Track Title')
        end
      end
    end
  end

  describe "Event system integration" do
    let(:content) { create(:content, theme: "Event Test Content") }
    let!(:audio) do
      audio = create(:audio, :completed, content: content)
      tempfile = Tempfile.new([ 'event_test_audio', '.mp3' ])
      tempfile.write("dummy audio content for event test")
      tempfile.rewind

      audio.audio = tempfile
      audio.save!
      tempfile.close
      tempfile.unlink
      audio
    end

    before do
      visit content_path(content)
    end

    it "dispatches unified audio:play event", js: true do
      # Add a listener for the unified event
      page.execute_script(<<~JS)
        window.testEventReceived = false;
        document.addEventListener('audio:play', function(event) {
          console.log('Unified audio:play event received:', event.detail);
          window.testEventReceived = true;
          window.testEventDetail = event.detail;
        });
      JS

      # Click the play button
      find('button[data-controller="audio-play-button"]').click

      # Wait for event to be dispatched
      wait_for(5.seconds) { page.evaluate_script('window.testEventReceived') }

      # Verify the event was received with correct data
      expect(page.evaluate_script('window.testEventReceived')).to be true

      event_detail = page.evaluate_script('window.testEventDetail')
      expect(event_detail['type']).to eq('content')
      expect(event_detail['title']).to eq(content.theme)
    end
  end
end
