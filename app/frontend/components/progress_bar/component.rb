module ProgressBar
  class Component < ApplicationViewComponent
    VARIANTS = {
      primary: "bg-blue-500",
      success: "bg-green-500",
      warning: "bg-yellow-500",
      danger: "bg-red-500"
    }.freeze

    SIZES = {
      small: "h-2",
      medium: "h-4",
      large: "h-6"
    }.freeze

    attr_reader :percentage, :label, :variant, :size, :show_percentage

    def initialize(percentage:, label: nil, variant: :primary, size: :medium, show_percentage: true)
      @percentage = [ 0, [ percentage.to_f, 100 ].min ].max.round(1)
      @label = label
      @variant = variant
      @size = size
      @show_percentage = show_percentage
    end

    private

    def bar_classes
      [
        "rounded-full transition-all duration-300 ease-out",
        VARIANTS[variant],
        SIZES[size]
      ].compact.join(" ")
    end

    def container_classes
      [
        "w-full bg-gray-200 rounded-full overflow-hidden",
        SIZES[size]
      ].compact.join(" ")
    end

    def progress_style
      "width: #{percentage}%"
    end
  end
end
