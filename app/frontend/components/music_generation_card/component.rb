# frozen_string_literal: true

class MusicGenerationCard::Component < ApplicationViewComponent
  attr_reader :music_generation

  def initialize(music_generation:)
    @music_generation = music_generation
  end

  def card_title
    "生成リクエスト ##{music_generation.id}"
  end

  def formatted_created_at
    music_generation.created_at.strftime("%Y年%-m月%-d日 %H:%M")
  end

  def has_tracks?
    music_generation.tracks.any?
  end

  def waiting_message
    case music_generation.status.to_sym
    when :pending
      "音楽生成の開始を待っています..."
    when :processing
      "音楽を生成中です..."
    when :failed
      "生成中にエラーが発生しました"
    else
      nil
    end
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

  private

  def status_badge_component
    MusicGenerationStatusBadge::Component.new(music_generation: music_generation)
  end

  def track_table_component
    TrackTable::Component.new(
      tracks: music_generation.tracks,
      show_pagination: false,
      show_content_column: false,
      empty_message: "トラックがありません"
    )
  end
end
