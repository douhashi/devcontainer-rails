# frozen_string_literal: true

class ArtworkThumbnailStatusBadge::Component < ApplicationViewComponent
  attr_reader :artwork

  def initialize(artwork:)
    @artwork = artwork
  end

  def status_text
    case artwork.thumbnail_generation_status.to_sym
    when :pending
      "未生成"
    when :processing
      "生成中"
    when :completed
      "生成済み"
    when :failed
      "失敗"
    else
      artwork.thumbnail_generation_status
    end
  end

  def status_classes
    base_classes = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full"

    status_specific_classes = case artwork.thumbnail_generation_status.to_sym
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
    artwork.thumbnail_generation_status.to_sym == :processing
  end

  def aria_label
    "アートワーク#{artwork.id}のサムネイル生成ステータス: #{status_text}"
  end
end
