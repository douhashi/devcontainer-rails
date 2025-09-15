# frozen_string_literal: true

module Icon
  class Component < ApplicationViewComponent
    # Font Awesome icon name mappings
    FA_ICONS = {
      image: "fa-image",
      music: "fa-music",
      video: "fa-video",
      delete: "fa-trash",
      spinner: "fa-spinner",
      play: "fa-play",
      play_circle: "fa-play-circle",
      pause: "fa-pause",
      check: "fa-check",
      edit: "fa-pen-to-square",
      plus: "fa-plus",
      arrow_left: "fa-arrow-left",
      schedule: "fa-clock",
      check_circle: "fa-check-circle",
      download: "fa-download",
      volume_high: "fa-volume-high",
      volume_low: "fa-volume-low",
      volume_off: "fa-volume-off",
      volume_xmark: "fa-volume-xmark",
      error: "fa-exclamation-triangle",
      copy: "fa-copy"
    }.freeze

    # Font Awesome size mappings
    FA_SIZES = {
      sm: "fa-sm",
      md: nil, # Default size, no class needed
      lg: "fa-lg"
    }.freeze

    attr_reader :name, :size, :color, :aria_label

    def initialize(name:, size: :md, color: nil, aria_label: nil)
      @name = name.to_sym
      @size = size.to_sym
      @color = color
      @aria_label = aria_label

      validate_icon!
      validate_size!
    end

    private

    def css_classes
      classes = [ "fa-solid", FA_ICONS[name] ]
      classes << FA_SIZES[size] if FA_SIZES[size]
      classes << "fa-spin" if spinner?
      classes << color if color.present?
      classes.compact.join(" ")
    end

    def icon_attributes
      attrs = {
        class: css_classes
      }

      if aria_label.present?
        attrs[:"aria-label"] = aria_label
        attrs[:role] = "img"
      else
        attrs[:"aria-hidden"] = "true"
      end

      attrs
    end

    def spinner?
      name == :spinner
    end

    def validate_icon!
      return if FA_ICONS.key?(name)

      raise ArgumentError, "Unknown icon: #{name}. Available icons: #{FA_ICONS.keys.join(', ')}"
    end

    def validate_size!
      return if FA_SIZES.key?(size)

      raise ArgumentError, "Invalid size: #{size}. Available sizes: #{FA_SIZES.keys.join(', ')}"
    end
  end
end
