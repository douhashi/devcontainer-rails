# frozen_string_literal: true

class ImageThumbnail::Component < ApplicationViewComponent
  attr_reader :image_url, :label, :image_type, :selected, :artwork, :is_placeholder

  def initialize(image_url:, label:, image_type:, selected: false, artwork: nil, is_placeholder: false)
    @image_url = image_url
    @label = label
    @image_type = image_type
    @selected = selected
    @artwork = artwork
    @is_placeholder = is_placeholder
  end

  def thumbnail_container_class
    base_class = "relative rounded-lg overflow-hidden transition-all duration-200 transform"

    classes = if is_placeholder
      "#{base_class} opacity-60 cursor-not-allowed"
    elsif selected
      "#{base_class} cursor-pointer ring-2 ring-blue-500 bg-blue-50 shadow-lg scale-105"
    else
      "#{base_class} cursor-pointer opacity-75 hover:opacity-100 hover:ring-2 hover:ring-blue-300 hover:scale-105 hover:shadow-xl"
    end

    classes
  end

  def thumbnail_image_class
    "w-full h-full object-cover transition-transform duration-200"
  end

  def label_class
    "absolute bottom-0 left-0 right-0 bg-black bg-opacity-70 text-white text-xs px-2 py-1 text-center"
  end

  def regenerate_thumbnail_path
    return nil unless artwork
    Rails.application.routes.url_helpers.regenerate_thumbnail_content_artwork_path(artwork.content, artwork)
  end
end
