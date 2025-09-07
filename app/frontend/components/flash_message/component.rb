# frozen_string_literal: true

class FlashMessage::Component < ApplicationViewComponent
  attr_reader :type, :message

  def initialize(type:, message:)
    @type = type.to_s
    @message = message
  end

  def css_classes
    base_classes = "px-4 py-3 rounded-lg mb-4 flex items-center justify-between"
    variant_classes = case type
    when "notice", "success"
      "bg-green-900 text-green-300 border border-green-800"
    when "alert", "error"
      "bg-red-900 text-red-300 border border-red-800"
    when "warning"
      "bg-yellow-900 text-yellow-300 border border-yellow-800"
    else
      "bg-blue-900 text-blue-300 border border-blue-800"
    end
    "#{base_classes} #{variant_classes}"
  end

  def icon
    case type
    when "notice", "success"
      "✓"
    when "alert", "error"
      "✕"
    when "warning"
      "⚠"
    else
      "ℹ"
    end
  end
end
