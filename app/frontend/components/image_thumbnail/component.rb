# frozen_string_literal: true

class ImageThumbnail::Component < ApplicationViewComponent
  attr_reader :image_url, :label, :image_type, :selected, :artwork

  def initialize(image_url:, label:, image_type:, selected: false, artwork: nil)
    @image_url = image_url
    @label = label
    @image_type = image_type
    @selected = selected
    @artwork = artwork
  end

  def thumbnail_container_class
    base_class = "relative cursor-pointer rounded-lg overflow-hidden"

    if selected
      "#{base_class} ring-2 ring-blue-500 bg-blue-50"
    else
      "#{base_class} hover:ring-2 hover:ring-blue-300 transition-all"
    end
  end

  def thumbnail_image_class
    "w-full h-full object-cover"
  end

  def label_class
    "absolute bottom-0 left-0 right-0 bg-black bg-opacity-70 text-white text-xs px-2 py-1 text-center"
  end

  def regenerate_thumbnail_path
    return nil unless artwork
    Rails.application.routes.url_helpers.regenerate_thumbnail_content_artwork_path(artwork.content, artwork)
  end
end
