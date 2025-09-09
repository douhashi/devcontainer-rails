# frozen_string_literal: true

module Icon
  class Component < ApplicationViewComponent
    SIZES = {
      sm: "w-4 h-4",
      md: "w-5 h-5",
      lg: "w-6 h-6"
    }.freeze

    ICONS = {
      image: "m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z",
      music: "m9 9 10.5-3m0 6.553v3.75a2.25 2.25 0 0 1-1.632 2.163l-1.32.377a1.803 1.803 0 1 1-.99-3.467l2.31-.66a2.25 2.25 0 0 0 1.632-2.163Zm0 0V2.25L9 5.25v10.303m0 0v3.75a2.25 2.25 0 0 1-1.632 2.163l-1.32.377a1.803 1.803 0 0 1-.99-3.467l2.31-.66A2.25 2.25 0 0 0 9 15.553Z",
      video: "m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z",
      delete: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
      spinner: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z",
      play: "M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z",
      pause: "M15.75 5.25v13.5m-7.5-13.5v13.5",
      check: "M4.5 12.75l6 6 9-13.5"
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
      classes = [ SIZES[size] ]
      classes << color if color.present?
      classes.compact.join(" ")
    end

    def icon_path
      ICONS[name]
    end

    def validate_icon!
      return if ICONS.key?(name)

      raise ArgumentError, "Unknown icon: #{name}. Available icons: #{ICONS.keys.join(', ')}"
    end

    def validate_size!
      return if SIZES.key?(size)

      raise ArgumentError, "Invalid size: #{size}. Available sizes: #{SIZES.keys.join(', ')}"
    end

    def svg_attributes
      attrs = {
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        "stroke-width": "1.5",
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

    def path_attributes
      {
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        d: icon_path
      }
    end

    def spinner?
      name == :spinner
    end

    def spinner_svg_attributes
      {
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24",
        fill: "currentColor",
        class: css_classes
      }.tap do |attrs|
        if aria_label.present?
          attrs[:"aria-label"] = aria_label
          attrs[:role] = "img"
        else
          attrs[:"aria-hidden"] = "true"
        end
      end
    end

    def spinner_circle_attributes
      {
        class: "opacity-25",
        cx: "12",
        cy: "12",
        r: "10",
        stroke: "currentColor",
        "stroke-width": "4"
      }
    end

    def spinner_path_attributes
      {
        class: "opacity-75",
        fill: "currentColor",
        d: icon_path
      }
    end
  end
end
