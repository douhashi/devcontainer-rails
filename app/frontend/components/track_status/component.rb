# frozen_string_literal: true

class TrackStatus::Component < ApplicationViewComponent
  attr_reader :track

  def initialize(track:)
    @track = track
  end

  def status_text
    case track.status.to_sym
    when :pending
      "待機中"
    when :processing
      "生成中"
    when :completed
      "完了"
    when :failed
      "失敗"
    else
      track.status
    end
  end

  def status_classes
    base_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"

    status_specific_classes = case track.status.to_sym
    when :pending
      "bg-gray-100 text-gray-700"
    when :processing
      "bg-blue-100 text-blue-700 animate-pulse"
    when :completed
      "bg-green-100 text-green-700"
    when :failed
      "bg-red-100 text-red-700"
    else
      "bg-gray-100 text-gray-700"
    end

    "#{base_classes} #{status_specific_classes}"
  end

  def show_progress_indicator?
    track.status.to_sym == :processing
  end
end
