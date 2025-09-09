# frozen_string_literal: true

class ContentPlayButton::Component < ApplicationViewComponent
  attr_reader :content_record, :size

  def initialize(content_record:, size: :medium)
    @content_record = content_record
    @size = size
  end

  def render?
    return false unless content_record.audio&.completed?
    return false unless content_record.audio&.audio&.present?

    true
  end

  private

  def button_id
    "content-play-button-#{content_record.id}"
  end

  def button_variant
    :primary
  end

  def button_size
    :md
  end

  def button_custom_class
    size_classes = case size
    when :small
      "p-1.5 w-8 h-8"
    when :large
      "p-3 w-12 h-12"
    else
      "p-2 w-10 h-10"
    end

    "rounded-full shadow-sm hover:shadow-md #{size_classes}"
  end

  def button_data
    {
      controller: "content-play-button",
      action: "click->content-play-button#playContent",
      "content-play-button-content-id-value": content_record.id,
      "content-play-button-theme-value": content_record.theme || "Untitled",
      "content-play-button-audio-url-value": content_record.audio.audio.url
    }
  end

  def icon_size
    case size
    when :small then :sm
    when :large then :lg
    else :md
    end
  end
end
