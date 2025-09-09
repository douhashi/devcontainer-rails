# frozen_string_literal: true

module Card
  class Component < ApplicationViewComponent
    VARIANTS = {
      default: "bg-gray-800",
      bordered: "bg-gray-800 border border-gray-600",
      elevated: "bg-gray-800 shadow-lg shadow-gray-900/30"
    }.freeze

    PADDINGS = {
      sm: "p-4",
      md: "p-6",
      lg: "p-8"
    }.freeze

    option :title, optional: true
    option :variant, default: proc { :default }
    option :padding, default: proc { :md }
    option :class, default: proc { "" }, as: :custom_class

    renders_one :header
    renders_one :footer
    renders_one :actions

    private

    def css_classes
      classes = [
        "rounded-lg",
        variant_classes,
        padding_classes,
        custom_class
      ]

      classes.compact.join(" ")
    end

    def variant_classes
      VARIANTS[variant.to_sym] || VARIANTS[:default]
    end

    def padding_classes
      PADDINGS[padding.to_sym] || PADDINGS[:md]
    end
  end
end
