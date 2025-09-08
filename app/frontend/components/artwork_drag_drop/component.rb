# frozen_string_literal: true

class ArtworkDragDrop::Component < ApplicationViewComponent
  attr_reader :content, :artwork

  def initialize(content_record:)
    @content = content_record
    @artwork = content_record.artwork || content_record.build_artwork
  end

  def has_artwork?
    artwork.persisted? && artwork.image.present?
  end

  def form_url
    if artwork.persisted?
      "/contents/#{content.id}/artworks/#{artwork.id}"
    else
      "/contents/#{content.id}/artworks"
    end
  end

  def form_method
    artwork.persisted? ? :patch : :post
  end

  def artwork_url
    return nil unless has_artwork?
    artwork.image.url
  end

  private

  def delete_button_class
    "absolute top-2 right-2 px-3 py-1 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700 transition-colors z-10"
  end

  def drop_zone_class
    base_class = "w-full h-full flex flex-col items-center justify-center border-2 border-dashed rounded-lg transition-all cursor-pointer"

    if has_artwork?
      "#{base_class} border-transparent"
    else
      "#{base_class} border-gray-600 bg-gray-800 hover:border-blue-500 hover:bg-gray-750"
    end
  end

  def placeholder_icon_svg
    <<~SVG.html_safe
      <svg class="w-16 h-16 text-gray-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
      </svg>
    SVG
  end
end
