module StatusBadge
  class Component < ApplicationViewComponent
    STATUS_CONFIG = {
      completed: {
        text: "完了",
        color_classes: "bg-green-100 text-green-800 border-green-200"
      },
      in_progress: {
        text: "制作中",
        color_classes: "bg-yellow-100 text-yellow-800 border-yellow-200"
      },
      needs_attention: {
        text: "要対応",
        color_classes: "bg-red-100 text-red-800 border-red-200"
      },
      not_started: {
        text: "未着手",
        color_classes: "bg-gray-100 text-gray-800 border-gray-200"
      },
      # Audio statuses
      pending: {
        text: "未作成",
        color_classes: "bg-gray-100 text-gray-600 border-gray-200"
      },
      processing: {
        text: "作成中",
        color_classes: "bg-blue-100 text-blue-800 border-blue-200 animate-pulse"
      },
      failed: {
        text: "失敗",
        color_classes: "bg-red-100 text-red-800 border-red-200"
      }
    }.freeze

    SIZE_CLASSES = {
      small: "text-xs px-2 py-1",
      medium: "text-sm px-3 py-1",
      large: "text-base px-4 py-2"
    }.freeze

    attr_reader :status, :size, :custom_class

    def initialize(status:, size: :medium, class: nil)
      @status = status
      @size = size
      @custom_class = binding.local_variable_get(:class)
    end

    private

    def status_text
      STATUS_CONFIG.dig(status, :text) || status.to_s.humanize
    end

    def color_classes
      STATUS_CONFIG.dig(status, :color_classes) || STATUS_CONFIG[:not_started][:color_classes]
    end

    def size_classes
      SIZE_CLASSES[size] || SIZE_CLASSES[:medium]
    end

    def badge_classes
      [
        "inline-flex items-center font-medium rounded-full border",
        color_classes,
        size_classes,
        custom_class
      ].compact.join(" ")
    end
  end
end
