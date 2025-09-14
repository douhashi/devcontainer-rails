# frozen_string_literal: true

class ArtworkGallery::Component < ApplicationViewComponent
  attr_reader :artwork

  def initialize(artwork:)
    @artwork = artwork
  end

  def should_render?
    artwork&.image&.present?
  end

  def thumbnail_images
    return [] unless should_render?

    images = []

    # オリジナル画像
    images << {
      image_url: artwork.image.url,
      label: "オリジナル",
      image_type: "original",
      selected: true, # デフォルトではオリジナルが選択されている
      artwork: artwork
    }

    # YouTubeサムネイル
    if artwork.has_youtube_thumbnail?
      images << {
        image_url: artwork.youtube_thumbnail_url,
        label: "YouTube",
        image_type: "youtube",
        selected: false,
        artwork: artwork
      }
    elsif artwork.thumbnail_generation_status_processing?
      # YouTube用サムネイル生成中のプレースホルダー
      images << {
        image_url: nil,
        label: "YouTube（生成中）",
        image_type: "youtube_placeholder",
        selected: false,
        is_placeholder: true,
        artwork: artwork
      }
    end

    images
  end

  def gallery_container_class
    "artwork-gallery mt-4 grid grid-cols-2 gap-2 max-w-xs mx-auto"
  end
end
