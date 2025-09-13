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
    if title
      page.has_css?('#floating-audio-player:not(.hidden)') &&
        within('#floating-audio-player') { page.has_content?(title) }
    else
      page.has_css?('#floating-audio-player:not(.hidden)')
    end
  end
end

RSpec.configure do |config|
  config.include MediaChromeHelpers, type: :system
end
