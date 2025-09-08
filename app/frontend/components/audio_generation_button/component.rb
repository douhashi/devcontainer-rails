module AudioGenerationButton
  class Component < ApplicationViewComponent
    attr_reader :content_record

    def initialize(content_record:)
      @content_record = content_record
    end

    private

    def can_generate_audio?
      return false unless content_record.tracks.completed.exists?
      return false unless content_record.artwork.present?

      # Check if we have enough completed tracks with duration information
      completed_tracks_count = content_record.tracks.completed.where.not(duration_sec: nil).count
      completed_tracks_count >= 2
    end

    def audio_exists?
      content_record.audio&.persisted?
    end

    def audio_status
      return nil unless audio_exists?
      content_record.audio.status
    end

    def button_text
      case audio_status
      when "pending"
        "音源生成待機中..."
      when "processing"
        "音源生成中..."
      when "completed"
        "音源を再生成"
      when "failed"
        "音源生成をリトライ"
      else
        "音源を生成"
      end
    end

    def button_classes
      base_classes = "inline-flex items-center px-6 py-3 rounded-lg font-medium transition-all duration-200"

      if can_generate_audio? && !processing?
        "#{base_classes} bg-green-600 hover:bg-green-700 text-white shadow-lg hover:shadow-xl"
      else
        "#{base_classes} bg-gray-600 text-gray-400 cursor-not-allowed"
      end
    end

    def processing?
      audio_status == "processing" || audio_status == "pending"
    end

    def disabled?
      !can_generate_audio? || processing?
    end

    def status_icon
      case audio_status
      when "pending"
        "⏳"
      when "processing"
        "🔄"
      when "completed"
        "✅"
      when "failed"
        "❌"
      else
        "🎵"
      end
    end

    def prerequisite_errors
      errors = []

      unless content_record.tracks.completed.exists?
        errors << "完成したトラックが必要です"
      end

      unless content_record.artwork.present?
        errors << "アートワークの設定が必要です"
      end

      completed_tracks_count = content_record.tracks.completed.where.not(duration_sec: nil).count
      if completed_tracks_count < 2
        errors << "最低2つの完成したトラックが必要です（現在: #{completed_tracks_count}個）"
      end

      errors
    end

    def audio_info
      return nil unless audio_exists?

      audio = content_record.audio
      {
        status: audio.status,
        created_at: audio.created_at,
        metadata: audio.metadata || {},
        has_file: audio.audio&.present?
      }
    end

    def audio_file_url
      return nil unless audio_exists? && audio_status == "completed"

      content_record.audio.audio&.url
    end

    def tooltip_text
      errors = prerequisite_errors
      return nil if errors.empty?

      errors.join(" / ")
    end

    def button_attributes
      {
        disabled: disabled?,
        title: disabled? ? tooltip_text : nil,
        class: button_classes,
        data: {
          controller: "audio-generation",
          action: "click->audio-generation#generate",
          audio_generation_content_id_value: content_record.id,
          turbo_confirm: (audio_status == "completed" ? "既存の音源を置き換えます。よろしいですか？" : nil)
        }
      }
    end
  end
end
