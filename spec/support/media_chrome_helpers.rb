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

  # Deprecated: FloatingAudioPlayer has been removed
  # These methods are kept as no-ops for backward compatibility
  # and will be removed in the next major version

  def wait_for_audio_player_visible
    # No-op: FloatingAudioPlayer has been removed
  end

  def wait_for_audio_player_hidden
    # No-op: FloatingAudioPlayer has been removed
  end

  def click_play_and_wait(selector)
    find(selector).click
    wait_for_media_chrome_ready
  end

  def player_showing?(title = nil)
    # Always return false as FloatingAudioPlayer has been removed
    false
  end

  def trigger_audio_ended
    # No-op: FloatingAudioPlayer has been removed
  end

  def play_button_shows_pause_icon?
    # Always return false as FloatingAudioPlayer has been removed
    false
  end

  def play_button_shows_play_icon?
    # Always return false as FloatingAudioPlayer has been removed
    false
  end

  def trigger_audio_play
    # No-op: FloatingAudioPlayer has been removed
  end

  def trigger_audio_pause
    # No-op: FloatingAudioPlayer has been removed
  end
end

RSpec.configure do |config|
  config.include MediaChromeHelpers, type: :system
end
