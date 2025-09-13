# frozen_string_literal: true

module MediaChromeHelpers
  # Wait for media-chrome controller to be ready
  def wait_for_media_chrome_ready(timeout: Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      loop do
        ready = page.evaluate_script(<<~JS)
          (() => {
            const controller = document.querySelector('media-controller');
            return controller && controller.media && controller.media.readyState >= 2;
          })()
        JS
        break if ready
        sleep 0.1
      end
    end
  rescue Timeout::Error
    # Continue even if media is not fully ready
  end

  # Wait for floating audio player to be visible
  def wait_for_audio_player_visible
    expect(page).to have_css('#floating-audio-player:not(.hidden)', wait: 10)
  end

  # Wait for floating audio player to be hidden
  def wait_for_audio_player_hidden
    expect(page).to have_css('#floating-audio-player.hidden', visible: :all, wait: 10)
  end

  # Click play button and wait for player to appear
  def click_play_and_wait(selector)
    find(selector).click
    wait_for_audio_player_visible
    wait_for_media_chrome_ready
  end

  # Simplified player state check
  def player_showing?(title = nil)
    player_visible = page.has_css?('#floating-audio-player:not(.hidden)')

    if title
      player_visible && within('#floating-audio-player') { page.has_content?(title) }
    else
      player_visible
    end
  end

  # Simulate audio ended event
  def trigger_audio_ended
    page.execute_script(<<~JS)
      const audioElement = document.querySelector('#floating-audio-player audio[slot="media"]');
      if (audioElement) {
        const endedEvent = new Event('ended');
        audioElement.dispatchEvent(endedEvent);
      }
    JS
  end

  # Check if play button shows pause icon (indicating playing state)
  def play_button_shows_pause_icon?
    within('#floating-audio-player') do
      play_icon_hidden = page.has_css?('[data-floating-audio-player-target="playIcon"].hidden', visible: :all)
      pause_icon_visible = page.has_css?('[data-floating-audio-player-target="pauseIcon"]:not(.hidden)')
      play_icon_hidden && pause_icon_visible
    end
  end

  # Check if play button shows play icon (indicating paused state)
  def play_button_shows_play_icon?
    within('#floating-audio-player') do
      play_icon_visible = page.has_css?('[data-floating-audio-player-target="playIcon"]:not(.hidden)')
      pause_icon_hidden = page.has_css?('[data-floating-audio-player-target="pauseIcon"].hidden', visible: :all)
      play_icon_visible && pause_icon_hidden
    end
  end

  # Trigger play event on audio element
  def trigger_audio_play
    page.execute_script(<<~JS)
      const audioElement = document.querySelector('#floating-audio-player audio[slot="media"]');
      const mediaController = document.querySelector('#floating-audio-player media-controller');

      if (audioElement) {
        const playEvent = new Event('play', { bubbles: true });
        audioElement.dispatchEvent(playEvent);
      }

      if (mediaController) {
        const playEvent = new Event('play', { bubbles: true });
        mediaController.dispatchEvent(playEvent);
      }
    JS
  end

  # Trigger pause event on audio element
  def trigger_audio_pause
    page.execute_script(<<~JS)
      const audioElement = document.querySelector('#floating-audio-player audio[slot="media"]');
      const mediaController = document.querySelector('#floating-audio-player media-controller');

      if (audioElement) {
        const pauseEvent = new Event('pause', { bubbles: true });
        audioElement.dispatchEvent(pauseEvent);
      }

      if (mediaController) {
        const pauseEvent = new Event('pause', { bubbles: true });
        mediaController.dispatchEvent(pauseEvent);
      }
    JS
  end
end

RSpec.configure do |config|
  config.include MediaChromeHelpers, type: :system
end
