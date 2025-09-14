module ArtworkLightbox
  class Component < ApplicationViewComponent
    attr_reader :variations, :initial_index

    def initialize(variations: [], initial_index: 0)
      @variations = variations
      @initial_index = initial_index
    end

    def render?
      variations.present?
    end

    def total_images
      variations.size
    end

    private

    def format_file_size(size_in_bytes)
      return "N/A" unless size_in_bytes

      size_in_bytes = size_in_bytes.to_i if size_in_bytes.is_a?(String)

      if size_in_bytes < 1024
        "#{size_in_bytes}B"
      elsif size_in_bytes < 1024 * 1024
        "#{(size_in_bytes / 1024.0).round(1)}KB"
      else
        "#{(size_in_bytes / (1024.0 * 1024.0)).round(1)}MB"
      end
    end

    def container_classes
      "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-90 transition-opacity duration-300 hidden opacity-0"
    end

    def close_button_classes
      "absolute top-4 right-4 z-10 p-2 rounded-full bg-gray-800 bg-opacity-75 text-white hover:bg-opacity-100 transition-colors"
    end

    def nav_button_classes
      "absolute top-1/2 transform -translate-y-1/2 p-3 rounded-full bg-gray-800 bg-opacity-75 text-white hover:bg-opacity-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
    end

    def metadata_classes
      "absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-6 text-white"
    end

    def counter_classes
      "absolute top-4 left-4 px-3 py-1 rounded-full bg-gray-800 bg-opacity-75 text-white text-sm"
    end

    def image_container_classes
      "relative max-w-7xl max-h-[90vh] mx-auto"
    end


    def close_icon
      helpers.tag.svg(
        class: "w-6 h-6",
        fill: "none",
        stroke: "currentColor",
        viewBox: "0 0 24 24",
        xmlns: "http://www.w3.org/2000/svg"
      ) do
        helpers.tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M6 18L18 6M6 6l12 12"
        )
      end
    end

    def previous_icon
      helpers.tag.svg(
        class: "w-6 h-6",
        fill: "none",
        stroke: "currentColor",
        viewBox: "0 0 24 24",
        xmlns: "http://www.w3.org/2000/svg"
      ) do
        helpers.tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M15 19l-7-7 7-7"
        )
      end
    end

    def next_icon
      helpers.tag.svg(
        class: "w-6 h-6",
        fill: "none",
        stroke: "currentColor",
        viewBox: "0 0 24 24",
        xmlns: "http://www.w3.org/2000/svg"
      ) do
        helpers.tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M9 5l7 7-7 7"
        )
      end
    end
  end
end
