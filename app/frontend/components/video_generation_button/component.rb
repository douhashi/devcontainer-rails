# frozen_string_literal: true

class VideoGenerationButton::Component < ApplicationViewComponent
  attr_reader :content_record

  def initialize(content_record:)
    @content_record = content_record
  end

  private

  def can_generate_video?
    content_record.video_generation_prerequisites_met?
  end

  def video_exists?
    content_record.video&.persisted?
  end

  def video_status
    return nil unless video_exists?
    content_record.video.status
  end

  def button_text
    case video_status
    when "pending", "processing"
      "作成中"  # Show text when processing
    when "completed", "failed"
      "削除"  # Delete button text
    else
      "動画を生成"
    end
  end

  def button_variant
    if video_status == "completed" || video_status == "failed"
      :danger
    else
      :primary  # Use primary instead of green for consistency
    end
  end

  def button_size
    :md
  end

  def button_loading?
    processing?
  end

  def button_disabled?
    if video_status == "completed" || video_status == "failed"
      delete_button_disabled?
    else
      !can_generate_video? || processing?
    end
  end

  def button_icon
    if video_status == "completed" || video_status == "failed"
      :delete
    elsif processing?
      nil  # No icon when loading (spinner is shown automatically)
    else
      :video
    end
  end

  def button_classes
    # This method can be removed after migration
    base_classes = "inline-flex items-center px-4 py-2 rounded-lg font-medium transition-all duration-200"

    if video_status == "completed" || video_status == "failed"
      "#{base_classes} bg-red-600 hover:bg-red-700 text-white"
    elsif can_generate_video? && !processing?
      "#{base_classes} bg-green-600 hover:bg-green-700 text-white"
    else
      "#{base_classes} bg-gray-400 text-gray-200 cursor-not-allowed opacity-50"
    end
  end

  def processing?
    video_status == "processing" || video_status == "pending"
  end

  def disabled?
    !can_generate_video? || processing?
  end

  def status_icon
    case video_status
    when "pending"
      "⏳"
    when "processing"
      "🔄"
    when "completed"
      "✅"
    when "failed"
      "❌"
    else
      "🎬"
    end
  end

  def prerequisite_errors
    content_record.video_generation_missing_prerequisites
  end

  def video_info
    return nil unless video_exists?

    video = content_record.video
    {
      status: video.status,
      created_at: video.created_at,
      resolution: video.resolution,
      file_size: video.file_size,
      duration_seconds: video.duration_seconds,
      has_file: video.video&.present?
    }
  end

  def video_file_url
    return nil unless video_exists? && video_status == "completed"

    content_record.video.video&.url
  end

  def formatted_file_size(size_bytes)
    return nil unless size_bytes

    if size_bytes < 1024 * 1024
      "#{(size_bytes / 1024.0).round(1)} KB"
    else
      "#{(size_bytes / 1024.0 / 1024.0).round(1)} MB"
    end
  end

  def formatted_duration(seconds)
    return nil unless seconds

    minutes = seconds / 60
    remaining_seconds = seconds % 60
    "#{minutes}:#{remaining_seconds.to_s.rjust(2, '0')}"
  end

  def tooltip_text
    errors = prerequisite_errors
    return nil if errors.empty?

    errors.join(" / ")
  end

  def button_data_attributes
    if video_status == "completed" || video_status == "failed"
      # Delete button data attributes
      {
        turbo_confirm: delete_confirmation_message
      }
    else
      # Generate button data attributes
      {
        controller: "video-generation",
        action: "click->video-generation#generate",
        video_generation_content_id_value: content_record.id
      }
    end
  end

  def button_attributes
    # Legacy method for backward compatibility
    if video_status == "completed" || video_status == "failed"
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
          controller: "video-generation",
          action: "click->video-generation#generate",
          video_generation_content_id_value: content_record.id
        }
      }
    end
  end

  def show_delete_button?
    false  # Integrated into main button
  end

  def delete_button_disabled?
    return false unless video_exists?
    video_status == "processing"
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
    return "動画を削除しますか？" unless video_exists?

    case video_status
    when "failed"
      "失敗した動画を削除しますか？"
    when "completed"
      "動画を削除しますか？削除後、再生成が可能になります。"
    else
      "動画を削除しますか？"
    end
  end

  def technical_specs
    {
      video_codec: "H.264 (libx264)",
      audio_codec: "AAC (192kbps, 48kHz)",
      frame_rate: "30fps",
      optimization: "YouTube推奨設定"
    }
  end

  def generation_duration
    return nil unless video_exists?
    return nil if content_record.video.created_at.blank? || content_record.video.updated_at.blank?

    (content_record.video.updated_at - content_record.video.created_at).to_i
  end

  def formatted_generation_duration
    duration = generation_duration
    return nil unless duration

    if duration < 60
      "#{duration}秒"
    else
      minutes = duration / 60
      seconds = duration % 60
      "#{minutes}分#{seconds}秒"
    end
  end
end
