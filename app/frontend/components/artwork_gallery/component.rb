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
      selected: true # デフォルトではオリジナルが選択されている
    }

    # YouTubeサムネイル
    if artwork.has_youtube_thumbnail?
      images << {
        image_url: artwork.youtube_thumbnail_url,
        label: "YouTube",
        image_type: "youtube",
        selected: false
      }
    end

    images
  end

  def gallery_container_class
    "artwork-gallery mt-4 flex gap-3 justify-center"
  end
end
