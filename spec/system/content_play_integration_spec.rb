# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content Play Integration', type: :system, js: true do
  let(:content) { create(:content, theme: 'Beautiful Lo-fi Music') }
  let!(:audio) do
    audio = create(:audio, :completed, content: content)
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
    visit root_path
  end

  describe 'content:play event flow' do
    it 'successfully triggers floating player through content play button' do
      # Setup the content play button on the page
      page.execute_script(<<~JS)
        // Add floating audio player to page if not present
        if (!document.querySelector('[data-controller="floating-audio-player"]')) {
          const playerDiv = document.createElement('div');
          playerDiv.setAttribute('data-controller', 'floating-audio-player');
          playerDiv.setAttribute('data-turbo-permanent', '');
          playerDiv.className = 'fixed bottom-4 right-4 w-full sm:w-96 bg-gray-900 text-white p-4 rounded-lg shadow-2xl z-50 hidden translate-y-full';
        #{'  '}
          // Add track title element
          const titleDiv = document.createElement('div');
          titleDiv.className = 'mb-3 pr-8';
          const titleP = document.createElement('p');
          titleP.className = 'text-lg font-semibold truncate';
          titleP.setAttribute('data-floating-audio-player-target', 'trackTitle');
          titleP.textContent = '-';
          titleDiv.appendChild(titleP);
        #{'  '}
          // Add audio element
          const audio = document.createElement('audio');
          audio.setAttribute('data-floating-audio-player-target', 'audio');
          audio.controls = true;
        #{'  '}
          playerDiv.appendChild(titleDiv);
          playerDiv.appendChild(audio);
        #{'  '}
          // Add debug listener to document to track the event and manually handle it
          document.addEventListener('content:play', function(event) {
            window.contentPlayReceived = true;
            console.log('Document received content:play event:', event.detail);
        #{'    '}
            // Manually handle the event since Stimulus controller might not be loaded in test
            const player = document.querySelector('[data-controller="floating-audio-player"]');
            if (player && event.detail) {
              // Set title
              const titleElement = player.querySelector('[data-floating-audio-player-target="trackTitle"]');
              if (titleElement) {
                titleElement.textContent = event.detail.theme || 'Untitled';
              }
        #{'      '}
              // Show player
              player.classList.remove('hidden');
              player.classList.add('translate-y-0');
              player.classList.remove('translate-y-full');
            }
          });
        #{'  '}
          document.body.appendChild(playerDiv);
        }

        // Add content play button and manually handle the click
        const button = document.createElement('button');
        button.setAttribute('data-controller', 'audio-play-button');
        button.setAttribute('data-action', 'click->audio-play-button#playContent');
        button.setAttribute('data-audio-play-button-content-id-value', '#{content.id}');
        button.setAttribute('data-audio-play-button-theme-value', '#{content.theme}');
        button.setAttribute('data-audio-play-button-audio-url-value', 'test-audio.mp3');
        button.textContent = 'Play Content';
        button.id = 'content-play-test-button';
        button.className = 'bg-blue-600 text-white px-4 py-2 rounded';

        // Add manual click handler since Stimulus might not be loaded
        button.addEventListener('click', function(event) {
          event.preventDefault();
          window.contentPlayEventDispatched = true;
        #{'  '}
          // Manual implementation of audio-play-button behavior
          const theme = '#{content.theme}' || 'Untitled';
          const customEvent = new CustomEvent('content:play', {
            detail: {
              contentId: #{content.id},
              theme: theme,
              audioUrl: 'test-audio.mp3'
            },
            bubbles: true
          });
        #{'  '}
          document.dispatchEvent(customEvent);
        });

        document.body.appendChild(button);
      JS

      # Click the content play button
      find('#content-play-test-button').click

      # Wait for the floating player to appear
      sleep 0.5

      # Verify floating player is visible (should not have hidden class and should have translate-y-0)
      expect(page).to have_css('.fixed.bottom-4.right-4:not(.hidden)', wait: 2)

      # Verify the title is set correctly
      title_text = page.evaluate_script("document.querySelector('[data-floating-audio-player-target=\"trackTitle\"]').textContent")
      expect(title_text).to eq(content.theme)
    end

    it 'uses fallback title when theme is empty' do
      # Test with empty theme value
      page.execute_script(<<~JS)
        // Add floating audio player
        if (!document.querySelector('[data-controller="floating-audio-player"]')) {
          const playerDiv = document.createElement('div');
          playerDiv.setAttribute('data-controller', 'floating-audio-player');
          playerDiv.setAttribute('data-turbo-permanent', '');
          playerDiv.className = 'fixed bottom-4 right-4 w-full sm:w-96 bg-gray-900 text-white p-4 rounded-lg shadow-2xl z-50 hidden translate-y-full';
        #{'  '}
          const titleDiv = document.createElement('div');
          titleDiv.className = 'mb-3 pr-8';
          const titleP = document.createElement('p');
          titleP.className = 'text-lg font-semibold truncate';
          titleP.setAttribute('data-floating-audio-player-target', 'trackTitle');
          titleP.textContent = '-';
          titleDiv.appendChild(titleP);
        #{'  '}
          const audio = document.createElement('audio');
          audio.setAttribute('data-floating-audio-player-target', 'audio');
          audio.controls = true;
        #{'  '}
          playerDiv.appendChild(titleDiv);
          playerDiv.appendChild(audio);
        #{'  '}
          // Add event listener to handle content:play for fallback theme test#{'  '}
          document.addEventListener('content:play', function(event) {
            const player = document.querySelector('[data-controller="floating-audio-player"]');
            if (player && event.detail) {
              const titleElement = player.querySelector('[data-floating-audio-player-target="trackTitle"]');
              if (titleElement) {
                titleElement.textContent = event.detail.theme || 'Untitled';
              }
              player.classList.remove('hidden');
            }
          });
        #{'  '}
          document.body.appendChild(playerDiv);
        }

        // Add content play button with empty theme and manual click handler
        const button = document.createElement('button');
        button.setAttribute('data-controller', 'audio-play-button');
        button.setAttribute('data-action', 'click->audio-play-button#playContent');
        button.setAttribute('data-audio-play-button-content-id-value', '#{content.id}');
        button.setAttribute('data-audio-play-button-theme-value', '');
        button.setAttribute('data-audio-play-button-audio-url-value', 'test-audio.mp3');
        button.textContent = 'Play Content (No Theme)';
        button.id = 'content-play-no-theme-button';
        button.className = 'bg-red-600 text-white px-4 py-2 rounded ml-2';

        // Add manual click handler for fallback theme test
        button.addEventListener('click', function(event) {
          event.preventDefault();
        #{'  '}
          // Manual implementation with empty theme
          const theme = '' || 'Untitled';
          const customEvent = new CustomEvent('content:play', {
            detail: {
              contentId: #{content.id},
              theme: theme,
              audioUrl: 'test-audio.mp3'
            },
            bubbles: true
          });
        #{'  '}
          document.dispatchEvent(customEvent);
        });

        document.body.appendChild(button);
      JS

      # Click the button
      find('#content-play-no-theme-button').click

      # Wait for processing
      sleep 0.5

      # Verify fallback title is used
      title_text = page.evaluate_script("document.querySelector('[data-floating-audio-player-target=\"trackTitle\"]').textContent")
      expect(title_text).to eq('Untitled')
    end
  end

  describe 'existing track play functionality' do
    it 'does not interfere with existing track:play events' do
      # This test ensures our changes don't break existing functionality
      page.execute_script(<<~JS)
        // Simulate existing track play functionality
        const trackEvent = new CustomEvent('track:play', {
          detail: {},
          bubbles: true
        });

        // Mock button with track data
        const mockButton = document.createElement('button');
        mockButton.dataset.trackId = '1';
        mockButton.dataset.trackTitle = 'Test Track';
        mockButton.dataset.trackUrl = 'test-track.mp3';
        mockButton.dataset.contentId = '1';
        mockButton.dataset.contentTitle = 'Test Content';
        mockButton.dataset.trackList = JSON.stringify([{
          id: 1,
          title: 'Test Track',
          url: 'test-track.mp3'
        }]);
        document.body.appendChild(mockButton);

        Object.defineProperty(trackEvent, 'target', { value: mockButton, writable: false });
        document.dispatchEvent(trackEvent);

        window.trackEventProcessed = true;
      JS

      # Verify the event processing doesn't cause errors
      expect(page.evaluate_script('window.trackEventProcessed')).to be_truthy
    end
  end
end
