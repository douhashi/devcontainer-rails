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
      "max-w-md w-full", # Increased from max-w-xs to max-w-md (400px) for better seek bar
      "min-w-0", # Allow shrinking
      "[&_media-controller]:text-sm", # Make controls smaller
      "[&_media-controller]:bg-transparent", # Transparent background
      "[&_media-controller]:border-gray-600", # Dark border
      "[&_media-control-bar]:min-h-0", # Reduce control height
      "[&_media-control-bar]:py-1", # Reduce vertical padding
      "[&_media-control-bar]:bg-gray-800", # Ensure dark controls
      "[&_media-time-range]:h-2", # Progress bar height
      "[&_media-play-button]:text-gray-300", # Light text for play button
      "[&_media-play-button:hover]:text-white", # White on hover
      "[&_media-time-display]:text-gray-300", # Light text for time display
      "[&_media-volume-range]:max-w-[80px]" # Limit volume control width
    ].join(" ")
  end
end
