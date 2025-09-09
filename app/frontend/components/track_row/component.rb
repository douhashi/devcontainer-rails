# frozen_string_literal: true

class TrackRow::Component < ApplicationViewComponent
  attr_reader :track, :show_content_column

  def initialize(track:, show_content_column: true)
    @track = track
    @show_content_column = show_content_column
  end

  private

  def track_id
    track.id
  end

  def dom_id
    "track_#{track_id}"
  end

  def track_title
    track.metadata_title || "生成中..."
  end

  def content_link?
    track.content&.present?
  end

  def content_theme
    track.content&.theme
  end


  def formatted_created_at
    I18n.l(track.created_at, format: :short)
  end

  def show_audio_player?
    track.status.completed? && track.audio.present?
  end

  def show_no_audio_message?
    track.status.completed? && !track.audio.present?
  end

  def show_processing_message?
    track.status.processing?
  end

  def play_button_component
    return unless show_audio_player?

    AudioPlayButton::Component.new(track: track)
  end

  def track_status_badge_component
    TrackStatusBadge::Component.new(track: track)
  end
end
