module StatusFilter
  class Component < ApplicationViewComponent
    FILTER_OPTIONS = [
      { status: "all", text: "全て" },
      { status: "completed", text: "完了" },
      { status: "in_progress", text: "制作中" },
      { status: "needs_attention", text: "要対応" },
      { status: "not_started", text: "未着手" }
    ].freeze

    attr_reader :selected_status

    def initialize(selected_status: nil)
      @selected_status = selected_status || "all"
    end

    private

    def filter_options
      FILTER_OPTIONS
    end

    def button_classes(status)
      base_classes = "px-4 py-2 text-sm font-medium rounded-lg border transition-colors duration-200"

      if active?(status)
        "#{base_classes} bg-blue-500 text-white border-blue-500"
      else
        "#{base_classes} bg-gray-200 text-gray-700 border-gray-300 hover:bg-gray-300"
      end
    end

    def active?(status)
      selected_status == status
    end
  end
end
