# frozen_string_literal: true

class AudioPlayer::Component < ApplicationViewComponent
  option :track
  option :autoplay, default: proc { false }

  private

  def should_render_audio_player?
    track.status.completed? && track.audio.present?
  end

  def audio_url
    track.audio.url
  end

  def autoplay_value
    autoplay.to_s
  end
end
