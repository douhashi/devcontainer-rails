module AudioInfoCard
  class Component < ApplicationViewComponent
    include Rails.application.routes.url_helpers

    attr_reader :audio

    def initialize(audio:)
      @audio = audio
    end

    def formatted_duration
      return "-" unless audio&.metadata&.dig("duration")

      duration = audio.metadata["duration"].to_i
      return "0:00" if duration.zero?

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
  end
end
