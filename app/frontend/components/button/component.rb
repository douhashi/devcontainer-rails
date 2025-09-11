# frozen_string_literal: true

module Button
  class Component < ApplicationViewComponent
    VARIANTS = {
      primary: "bg-blue-600 hover:bg-blue-700 text-white",
      secondary: "bg-gray-200 hover:bg-gray-300 text-gray-800",
      secondary_dark: "bg-gray-700 hover:bg-gray-600 text-gray-200",
      danger: "bg-red-600 hover:bg-red-700 text-white",
      ghost: "bg-transparent hover:bg-gray-100 text-gray-700 border border-gray-300"
    }.freeze

    SIZES = {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2 text-base",
      lg: "px-6 py-3 text-lg"
    }.freeze

    option :text, default: proc { "" }
    option :variant, default: proc { :primary }
    option :size, default: proc { :md }
    option :loading, default: proc { false }
    option :disabled, default: proc { false }
    option :type, default: proc { "button" }
    option :href, optional: true
    option :data, default: proc { {} }
    option :class, default: proc { "" }, as: :custom_class
    option :id, optional: true
    option :aria_label, optional: true
    option :onclick, optional: true

    private

    def css_classes
      base_rounded = custom_class.present? && custom_class.match?(/rounded-\w+/) ? "" : "rounded-lg"

      classes = [
        "inline-flex items-center justify-center",
        "font-medium",
        base_rounded,
        "transition-all duration-200",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        variant_classes,
        size_classes,
        state_classes,
        custom_class
      ]

      classes.compact.join(" ")
    end

    def variant_classes
      VARIANTS[variant.to_sym] || VARIANTS[:primary]
    end

    def size_classes
      SIZES[size.to_sym] || SIZES[:md]
    end

    def state_classes
      classes = []

      if loading || disabled
        classes << "cursor-not-allowed"
        classes << (loading ? "opacity-75" : "opacity-50")
      end

      classes.join(" ")
    end

    def button_attributes
      attrs = {
        class: css_classes,
        type: type,
        disabled: disabled || loading,
        data: data
      }

      attrs[:id] = id if id.present?
      attrs[:"aria-label"] = aria_label if aria_label.present?
      attrs[:onclick] = onclick if onclick.present?

      if loading
        attrs[:"aria-busy"] = "true"
      end

      if disabled
        attrs[:"aria-disabled"] = "true"
      end

      attrs
    end

    def link_attributes
      attrs = {
        class: css_classes,
        data: data
      }

      attrs[:id] = id if id.present?
      attrs[:"aria-label"] = aria_label if aria_label.present?
      attrs[:onclick] = onclick if onclick.present?

      if disabled
        attrs[:"aria-disabled"] = "true"
        attrs[:onclick] = "return false;"
      end

      attrs
    end

    def render_spinner
      %(<svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>).html_safe
    end

    def button_content
      content_parts = []
      content_parts << render_spinner if loading
      content_parts << (content.presence || text)
      safe_join(content_parts)
    end
  end
end
