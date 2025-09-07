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
end
