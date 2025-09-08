# frozen_string_literal: true

class SingleTrackGenerationButton::Component < ApplicationViewComponent
  attr_reader :content_record

  def initialize(content_record:)
    @content_record = content_record
  end

  def can_generate?
    disability_reason.nil?
  end

  def disability_reason
    return "動画の長さが設定されていません" if content_record.duration_min.blank?
    return "音楽生成プロンプトが設定されていません" if content_record.audio_prompt.blank?
    return "BGM生成処理中です" if processing_tracks?
    return "トラック数の上限に達しています" if would_exceed_limit?

    nil
  end

  def button_text
    return "生成中..." if processing_tracks?

    "音楽生成（2曲）"
  end

  def confirmation_message
    "1回のAPI呼び出しで2曲生成します。よろしいですか？"
  end

  def generate_single_track_url
    Rails.application.routes.url_helpers.generate_single_track_content_path(content_record)
  end

  private

  def processing_tracks?
    content_record.tracks.exists?(status: :processing)
  end

  def would_exceed_limit?
    current_count = content_record.tracks.count
    current_count >= 100 # TrackQueueingService::MAX_TRACKS_PER_CONTENT
  end
end
