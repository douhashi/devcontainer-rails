# frozen_string_literal: true

class ExtendedTrackRow::Component < ApplicationViewComponent
  attr_reader :track, :music_generation, :is_group_start, :group_size

  def initialize(track:, music_generation:, is_group_start: false, group_size: 1)
    @track = track
    @music_generation = music_generation
    @is_group_start = is_group_start
    @group_size = group_size
  end

  private

  def track_id
    track.id
  end

  def music_generation_id
    music_generation.id
  end

  def formatted_duration
    track.formatted_duration
  end

  def row_classes
    classes = [ "transition-colors", "bg-gray-800/50" ]
    classes << "border-t-2 border-gray-600" if is_group_start
    classes.join(" ")
  end

  def show_audio_player?
    track.status.completed? && track.audio.present?
  end

  def play_button_component
    return unless show_audio_player?
    AudioPlayButton::Component.new(track: track)
  end

  def delete_path
    helpers.content_track_path(track.content, track)
  end
end
