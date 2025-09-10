# frozen_string_literal: true

class AudioUsedTracksTable::Component < ApplicationViewComponent
  attr_reader :audio

  def initialize(audio:)
    @audio = audio
  end

  def selected_tracks
    return [] unless audio

    track_ids = audio.metadata&.dig("selected_track_ids")
    return [] if track_ids.blank?

    # Get tracks and preserve the order of selected_track_ids
    tracks = Track.where(id: track_ids).index_by(&:id)
    track_ids.filter_map { |id| tracks[id] }
  end

  def has_tracks?
    selected_tracks.any?
  end

  def should_display?
    return false unless audio
    return false unless audio.status.completed?

    has_tracks?
  end

  def empty_message
    "使用Track情報なし"
  end

  def track_row_data
    selected_tracks.each_with_index.map do |track, index|
      {
        track: track,
        track_number: index + 1,
        track_title: track.metadata_title
      }
    end
  end

  private

  def render?
    should_display?
  end

  def play_button_component(track)
    return unless track.status.completed? && track.audio.present?
    AudioPlayButton::Component.new(track: track)
  end
end
