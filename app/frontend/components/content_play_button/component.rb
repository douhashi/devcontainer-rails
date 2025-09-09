# frozen_string_literal: true

class ContentPlayButton::Component < ApplicationViewComponent
  attr_reader :content_record, :size

  def initialize(content_record:, size: :medium)
    @content_record = content_record
    @size = size
  end

  def render?
    content_record.audio&.completed? && content_record.audio&.audio&.present?
  end

  private

  def button_id
    "content-play-button-#{content_record.id}"
  end


  def button_classes
    base_classes = "rounded-full transition-all duration-200 flex items-center justify-center bg-blue-600 hover:bg-blue-700 text-white shadow-sm hover:shadow-md"

    size_classes = case size
    when :small
      "p-1.5 w-8 h-8"
    when :large
      "p-3 w-12 h-12"
    else
      "p-2 w-10 h-10"
    end

    "#{base_classes} #{size_classes}"
  end

  def icon_size_classes
    case size
    when :small
      "w-4 h-4"
    when :large
      "w-6 h-6"
    else
      "w-5 h-5"
    end
  end
end
