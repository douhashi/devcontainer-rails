# frozen_string_literal: true

class TrackRequestRow::Component < ApplicationViewComponent
  attr_reader :track, :track_number

  def initialize(track:, track_number:)
    @track = track
    @track_number = track_number
  end

  private

  def track_id
    track.id
  end

  def track_title
    track.metadata_title || "-"
  end

  def formatted_duration
    track.formatted_duration
  end

  def formatted_created_at
    I18n.l(track.created_at, format: :long_with_time)
  end

  def show_audio_player?
    track.status.completed? && track.audio.present?
  end

  def play_button_component
    return unless show_audio_player?
    InlineAudioPlayer::Component.new(track: track)
  end

  def player_content
    if show_audio_player?
      render play_button_component
    elsif track.status.processing?
      content_tag :span, "処理中...", class: "text-gray-400"
    else
      content_tag :span, "利用不可", class: "text-gray-500"
    end
  end

  def row_classes
    "hover:bg-gray-700 transition-colors"
  end
end
