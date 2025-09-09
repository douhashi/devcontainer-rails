# frozen_string_literal: true

class Content::Card::Component < ApplicationViewComponent
  attr_reader :item

  def initialize(item:)
    @item = item
  end

  private

  def track_progress
    item.track_progress
  end

  def artwork_status
    item.artwork_status
  end

  def completion_status
    item.completion_status
  end

  def progress_variant
    case completion_status
    when :completed
      :success
    when :in_progress
      :primary
    when :needs_attention
      :danger
    else
      :primary
    end
  end

  def artwork_icon_classes
    case artwork_status
    when :configured
      "text-green-500"
    else
      "text-gray-400"
    end
  end

  def artwork_icon_text
    case artwork_status
    when :configured
      "✓"
    else
      "○"
    end
  end

  def artwork_thumbnail_url
    return nil unless item.artwork&.image&.present?
    item.artwork.image.url
  end

  def tracks_complete_icon_class
    item.tracks_complete? ? "text-green-500" : "text-gray-500"
  end

  def video_generated_icon_class
    item.video_generated? ? "text-green-500" : "text-gray-500"
  end

  def formatted_duration
    "#{item.duration_min}分"
  end

  def image_icon_svg
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
      </svg>
    SVG
  end

  def music_icon_svg
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="m9 9 10.5-3m0 6.553v3.75a2.25 2.25 0 0 1-1.632 2.163l-1.32.377a1.803 1.803 0 1 1-.99-3.467l2.31-.66a2.25 2.25 0 0 0 1.632-2.163Zm0 0V2.25L9 5.25v10.303m0 0v3.75a2.25 2.25 0 0 1-1.632 2.163l-1.32.377a1.803 1.803 0 0 1-.99-3.467l2.31-.66A2.25 2.25 0 0 0 9 15.553Z" />
      </svg>
    SVG
  end

  def video_icon_svg
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z" />
      </svg>
    SVG
  end
end
