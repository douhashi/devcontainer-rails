# frozen_string_literal: true

class AudioPlayer::Component < ApplicationViewComponent
  option :track
  option :css_class, default: proc { "" }
  option :autoplay, default: proc { false }

  # Only show player for completed tracks with audio
  def render?
    track.status.completed? && track.audio.present?
  end

  private

  def player_id
    @player_id ||= "audio-player-#{track.id}"
  end

  def audio_url
    track.audio.url
  end

  def table_optimized_classes
    [
      "max-w-xs w-full",
      "min-w-0", # Allow shrinking
      "[&_.plyr]:text-sm", # Make Plyr controls smaller
      "[&_.plyr--audio_.plyr__controls]:min-h-0", # Reduce control height
      "[&_.plyr--audio_.plyr__controls]:py-1", # Reduce vertical padding
      "[&_.plyr__progress]:h-1" # Make progress bar thinner
    ].join(" ")
  end
end
