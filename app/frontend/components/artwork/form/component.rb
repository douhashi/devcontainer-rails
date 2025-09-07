# frozen_string_literal: true

class Artwork::Form::Component < ApplicationViewComponent
  attr_reader :content, :artwork

  def initialize(content_record:)
    @content = content_record
    @artwork = content_record.artwork || content_record.build_artwork
  end

  private

  def form_url
    if artwork.persisted?
      content_artwork_path(content, artwork)
    else
      content_artworks_path(content)
    end
  end

  def form_method
    artwork.persisted? ? :patch : :post
  end

  def submit_button_text
    artwork.persisted? ? "画像を更新" : "画像をアップロード"
  end

  def has_image?
    artwork.image.present?
  end

  def image_url
    return nil unless has_image?
    artwork.image.url
  end

  def delete_button_class
    "px-4 py-2 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700 transition-colors"
  end

  def upload_button_class
    "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
  end
end
