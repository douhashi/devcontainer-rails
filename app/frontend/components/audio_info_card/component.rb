module AudioInfoCard
  class Component < ApplicationViewComponent
    include Rails.application.routes.url_helpers

    attr_reader :audio

    def initialize(audio:)
      @audio = audio
    end

    def formatted_duration
      # 使用トラックがある場合はその総和を計算
      if has_used_tracks?
        duration = calculate_total_tracks_duration
        return "-" if duration.zero?
      else
        # 使用トラックがない場合はmetadataから取得
        return "-" unless audio&.metadata&.dig("duration")
        duration = audio.metadata["duration"].to_i
        return "0:00" if duration.zero?
      end

      minutes = duration / 60
      seconds = duration % 60
      sprintf("%d:%02d", minutes, seconds)
    end

    def processing_time
      return "-" unless audio&.persisted?
      return "-" unless audio.created_at && audio.updated_at

      diff = (audio.updated_at - audio.created_at).to_i
      return "0秒" if diff == 0

      minutes = diff / 60
      seconds = diff % 60

      if minutes > 0
        "#{minutes}分#{seconds}秒"
      else
        "#{seconds}秒"
      end
    end

    def formatted_date(datetime)
      return "-" unless datetime

      I18n.l(datetime, format: "%Y年%m月%d日 %H:%M")
    end

    def status_symbol
      return :not_started unless audio

      case audio.status
      when "pending"
        :pending
      when "processing"
        :processing
      when "completed"
        :completed
      when "failed"
        :failed
      else
        :not_started
      end
    end

    def delete_path
      return nil unless audio

      content_audio_path(audio.content, audio)
    end

    private

    def render?
      true
    end

    def has_used_tracks?
      return false unless audio

      track_ids = audio.metadata&.dig("selected_track_ids")
      track_ids.present? && track_ids.any?
    end

    def calculate_total_tracks_duration
      return 0 unless audio

      track_ids = audio.metadata&.dig("selected_track_ids")
      return 0 if track_ids.blank?

      tracks = Track.where(id: track_ids)
      tracks.sum { |track| track.duration_sec.to_i }
    end
  end
end
