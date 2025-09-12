# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unified Audio Play Integration", type: :system, skip: "Temporarily skipped due to media-chrome/Selenium timing issues" do
  include_context "ログイン済み"

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

        # Click the play button - specifically the first content audio button
        find('button[data-controller="audio-play-button"][data-audio-play-button-type-value="content"]', match: :first).click

        # Wait for floating player to appear
        expect(page).to have_css('#floating-audio-player:not(.hidden)')

        # Check that the floating player shows the correct content
        within('#floating-audio-player') do
          expect(page).to have_content(content.theme)
        end
      end
    end

    context "when playing track audio" do
      let!(:music_generation) { create(:music_generation, :completed, content: content) }
      let!(:track) do
        track = create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { music_title: 'Test Track Title' })
        track
      end

      before do
        visit content_path(content)
      end

      it "plays track audio using unified system", js: true do
        # Look for the unified AudioPlayButton component for track
        expect(page).to have_css('button[data-audio-play-button-type-value="track"]')

        # Click the play button
        find('button[data-audio-play-button-type-value="track"]').click

        # Wait for floating player to appear
        expect(page).to have_css('#floating-audio-player:not(.hidden)')

        # Check that the floating player shows the correct track title
        within('#floating-audio-player') do
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
        window.testEventType = null;
        window.testEventTitle = null;
        document.addEventListener('audio:play', function(event) {
          console.log('Unified audio:play event received:', event.detail);
          window.testEventReceived = true;
          window.testEventType = event.detail.type;
          window.testEventTitle = event.detail.title;
        });
      JS

      # Click the play button - specifically the first content audio button
      find('button[data-controller="audio-play-button"][data-audio-play-button-type-value="content"]', match: :first).click

      # Wait for event to be dispatched
      expect(page).to have_css('body', wait: 5) # Give time for event to dispatch
      sleep 0.5 # Small delay to ensure event processing

      # Verify the event was received with correct data
      expect(page.evaluate_script('window.testEventReceived')).to be true
      expect(page.evaluate_script('window.testEventType')).to eq('content')
      expect(page.evaluate_script('window.testEventTitle')).to eq(content.theme)
    end
  end
end
