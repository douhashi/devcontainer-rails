module ArtworkVariations
  class GridComponent < ApplicationViewComponent
    attr_reader :artwork

    def initialize(artwork:)
      @artwork = artwork
    end

    def render?
      true
    end

    private

    def variations
      return [] unless artwork

      artwork.all_variations
    end

    def empty_state?
      artwork.nil? || variations.empty?
    end

    def grid_classes
      "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
    end

    def card_classes
      "variation-card bg-gray-800 rounded-lg overflow-hidden hover:ring-2 hover:ring-blue-500 transition-all duration-200"
    end

    def label_classes(type)
      base = "inline-block px-2 py-1 text-xs font-semibold rounded-full"

      case type
      when :original
        "#{base} bg-blue-500 text-white"
      when :youtube_thumbnail
        "#{base} bg-red-500 text-white"
      when :square
        "#{base} bg-purple-500 text-white"
      else
        "#{base} bg-gray-600 text-gray-100"
      end
    end

    def format_file_size(size_in_bytes)
      return "N/A" unless size_in_bytes

      # Convert string to integer if needed
      size_in_bytes = size_in_bytes.to_i if size_in_bytes.is_a?(String)

      if size_in_bytes < 1024
        "#{size_in_bytes}B"
      elsif size_in_bytes < 1024 * 1024
        "#{(size_in_bytes / 1024.0).round(1)}KB"
      else
        "#{(size_in_bytes / (1024.0 * 1024.0)).round(1)}MB"
      end
    end

    def download_icon
      helpers.tag.svg(
        class: "w-4 h-4",
        fill: "none",
        stroke: "currentColor",
        viewBox: "0 0 24 24",
        xmlns: "http://www.w3.org/2000/svg"
      ) do
        helpers.tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
        )
      end
    end
  end
end
