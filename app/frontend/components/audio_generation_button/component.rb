module AudioGenerationButton
  class Component < ApplicationViewComponent
    attr_reader :content_record

    def initialize(content_record:)
      @content_record = content_record
    end

    private

    def can_generate_audio?
      return false unless content_record.tracks.completed.exists?

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
      when "pending", "processing"
        "作成中"  # Show text when processing
      when "completed", "failed"
        "削除"  # Delete button text
      else
        "音源を生成"
      end
    end

    def button_variant
      if audio_status == "completed" || audio_status == "failed"
        :danger
      else
        :primary
      end
    end

    def button_size
      :md
    end

    def button_loading?
      processing?
    end

    def button_disabled?
      if audio_status == "completed" || audio_status == "failed"
        delete_button_disabled?
      else
        !can_generate_audio? || processing?
      end
    end

    def button_icon
      if audio_status == "completed" || audio_status == "failed"
        :delete
      elsif processing?
        nil  # No icon when loading (spinner is shown automatically)
      else
        :music
      end
    end

    def button_classes
      # This method can be removed after migration
      base_classes = "inline-flex items-center px-4 py-2 rounded-lg font-medium transition-all duration-200"

      if audio_status == "completed" || audio_status == "failed"
        "#{base_classes} bg-red-600 hover:bg-red-700 text-white"
      elsif can_generate_audio? && !processing?
        "#{base_classes} bg-blue-600 hover:bg-blue-700 text-white"
      else
        "#{base_classes} bg-gray-400 text-gray-200 cursor-not-allowed opacity-50"
      end
    end

    def processing?
      audio_status == "processing" || audio_status == "pending"
    end

    def disabled?
      !can_generate_audio? || processing?
    end

    def status_icon
      nil  # We'll use SVG icons instead of emoji
    end

    def prerequisite_errors
      errors = []

      unless content_record.tracks.completed.exists?
        errors << "トラックが必要"
      end

      completed_tracks_count = content_record.tracks.completed.where.not(duration_sec: nil).count
      if completed_tracks_count < 2
        errors << "トラック2個以上必要"
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

    def button_data_attributes
      if audio_status == "completed" || audio_status == "failed"
        # Delete button data attributes
        {
          turbo_confirm: delete_confirmation_message
        }
      else
        # Generate button data attributes
        {
          controller: "audio-generation",
          action: "click->audio-generation#generate",
          audio_generation_content_id_value: content_record.id
        }
      end
    end

    def button_attributes
      # Legacy method for backward compatibility
      if audio_status == "completed" || audio_status == "failed"
        # Delete button attributes
        {
          disabled: delete_button_disabled?,
          class: button_classes,
          data: {
            turbo_confirm: delete_confirmation_message
          }
        }
      else
        # Generate button attributes
        {
          disabled: disabled?,
          title: disabled? ? tooltip_text : nil,
          class: button_classes,
          data: {
            controller: "audio-generation",
            action: "click->audio-generation#generate",
            audio_generation_content_id_value: content_record.id
          }
        }
      end
    end

    def show_delete_button?
      false  # Integrated into main button
    end

    def delete_button_disabled?
      return false unless audio_exists?
      audio_status == "processing"
    end

    def delete_button_classes
      base_classes = "inline-flex items-center px-4 py-2 rounded-lg font-medium transition-all duration-200 text-white text-sm"

      if delete_button_disabled?
        "#{base_classes} bg-gray-400 cursor-not-allowed opacity-50"
      else
        "#{base_classes} bg-red-600 hover:bg-red-700"
      end
    end

    def delete_confirmation_message
      return "音源を削除しますか？" unless audio_exists?

      case audio_status
      when "failed"
        "失敗した音源を削除しますか？"
      when "completed"
        "音源を削除しますか？削除後、再生成が可能になります。"
      else
        "音源を削除しますか？"
      end
    end
  end
end
