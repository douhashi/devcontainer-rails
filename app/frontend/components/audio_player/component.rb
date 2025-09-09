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
      "[&_.plyr--audio]:bg-gray-800", # Dark background
      "[&_.plyr--audio]:border-gray-600", # Dark border
      "[&_.plyr--audio_.plyr__controls]:min-h-0", # Reduce control height
      "[&_.plyr--audio_.plyr__controls]:py-1", # Reduce vertical padding
      "[&_.plyr--audio_.plyr__controls]:bg-gray-800", # Ensure dark controls
      "[&_.plyr__progress]:h-1", # Make progress bar thinner
      "[&_.plyr__control]:text-gray-300", # Light text for controls
      "[&_.plyr__control:hover]:text-white", # White on hover
      "[&_.plyr__time]:text-gray-300" # Light text for time display
    ].join(" ")
  end
end
