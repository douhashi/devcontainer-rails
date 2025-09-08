# frozen_string_literal: true

class TrackStatusBadge::Component < ApplicationViewComponent
  attr_reader :track

  def initialize(track:)
    @track = track
  end

  def status_text
    case track.status.to_sym
    when :pending
      "待機中"
    when :processing
      "処理中"
    when :completed
      "完了"
    when :failed
      "失敗"
    else
      track.status
    end
  end

  def status_classes
    base_classes = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full"

    status_specific_classes = case track.status.to_sym
    when :pending
      "bg-gray-600 text-gray-200"
    when :processing
      "bg-yellow-600 text-yellow-200"
    when :completed
      "bg-green-600 text-green-200"
    when :failed
      "bg-red-600 text-red-200"
    else
      "bg-gray-600 text-gray-200"
    end

    "#{base_classes} #{status_specific_classes}"
  end

  def show_progress_indicator?
    track.status.to_sym == :processing
  end

  def aria_label
    "トラック#{track.id}のステータス: #{status_text}"
  end
end
