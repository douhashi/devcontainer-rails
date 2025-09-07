# frozen_string_literal: true

class TrackCounter::Component < ApplicationViewComponent
  attr_reader :content_record, :current_count, :max_count

  def initialize(content_record:, current_count: nil, max_count: 100)
    @content_record = content_record
    @current_count = current_count || content_record.tracks.count
    @max_count = max_count
  end

  def remaining_count
    max_count - current_count
  end

  def progress_percentage
    return 100 if current_count >= max_count
    ((current_count.to_f / max_count) * 100).round
  end

  def status_color
    percentage = progress_percentage
    if percentage >= 95
      "red"
    elsif percentage >= 80
      "yellow"
    else
      "green"
    end
  end

  def can_generate_more?
    current_count < max_count
  end

  def status_text
    if can_generate_more?
      "残り: #{remaining_count}件"
    else
      "上限に達しました"
    end
  end

  def progress_bar_classes
    base = "h-2 rounded-full transition-all duration-300"
    color_class = case status_color
    when "red"
      "bg-red-500"
    when "yellow"
      "bg-yellow-500"
    else
      "bg-green-500"
    end
    "#{base} #{color_class}"
  end

  def status_text_classes
    case status_color
    when "red"
      "text-red-600 font-semibold"
    when "yellow"
      "text-yellow-600 font-semibold"
    else
      "text-gray-600"
    end
  end
end
