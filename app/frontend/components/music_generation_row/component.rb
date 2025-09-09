# frozen_string_literal: true

class MusicGenerationRow::Component < ApplicationViewComponent
  attr_reader :music_generation

  def initialize(music_generation:)
    @music_generation = music_generation
  end

  private

  def music_generation_id
    music_generation.id
  end

  def dom_id
    "music_generation_#{music_generation_id}"
  end

  def formatted_created_at
    I18n.l(music_generation.created_at, format: :short)
  end

  def tracks_count
    music_generation.tracks.count
  end

  def formatted_total_duration
    tracks_with_duration = music_generation.tracks.where.not(duration_sec: nil)
    return "-" if tracks_with_duration.empty?

    total_seconds = tracks_with_duration.sum(:duration_sec)
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60

    if hours > 0
      "%d:%02d:%02d" % [ hours, minutes, seconds ]
    else
      "%d:%02d" % [ minutes, seconds ]
    end
  end

  def status_badge_component
    MusicGenerationStatusBadge::Component.new(music_generation: music_generation)
  end

  def delete_url
    Rails.application.routes.url_helpers.content_music_generation_path(
      music_generation.content,
      music_generation
    )
  end

  def delete_confirmation_message
    "この音楽生成リクエストを削除しますか？関連するトラックもすべて削除されます。この操作は取り消せません。"
  end
end
