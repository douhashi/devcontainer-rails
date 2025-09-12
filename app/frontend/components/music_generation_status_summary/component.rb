# frozen_string_literal: true

class MusicGenerationStatusSummary::Component < ApplicationViewComponent
  attr_reader :content_record

  def initialize(content_record:)
    @content_record = content_record
  end

  def status_counts
    @status_counts ||= content_record.music_generations.group(:status).count
  end

  def pending_count
    status_counts["pending"] || 0
  end

  def processing_count
    status_counts["processing"] || 0
  end

  def completed_count
    status_counts["completed"] || 0
  end

  def failed_count
    status_counts["failed"] || 0
  end

  def total_count
    content_record.music_generations.count
  end

  def status_config
    {
      pending: {
        label: "待機中",
        icon: "clock",
        color_class: "text-gray-500 bg-gray-100"
      },
      processing: {
        label: "処理中",
        icon: "spinner",
        color_class: "text-yellow-600 bg-yellow-100"
      },
      completed: {
        label: "完了",
        icon: "check-circle",
        color_class: "text-green-600 bg-green-100"
      },
      failed: {
        label: "失敗",
        icon: "exclamation-circle",
        color_class: "text-red-600 bg-red-100"
      }
    }
  end

  def status_item_classes(status)
    "inline-flex items-center px-3 py-1.5 rounded-lg text-sm font-medium #{status_config[status][:color_class]}"
  end
end
