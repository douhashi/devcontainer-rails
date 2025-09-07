# frozen_string_literal: true

class Toast::Component < ApplicationViewComponent
  attr_reader :message, :type

  def initialize(message:, type: :info)
    @message = message
    @type = type.to_sym
  end

  def toast_classes
    base_classes = "p-4 rounded-lg shadow-lg flex items-start space-x-3"

    type_classes = case type
    when :success
      "bg-green-50 text-green-800 border-green-200"
    when :error
      "bg-red-50 text-red-800 border-red-200"
    when :warning
      "bg-yellow-50 text-yellow-800 border-yellow-200"
    when :info
      "bg-blue-50 text-blue-800 border-blue-200"
    else
      "bg-gray-50 text-gray-800 border-gray-200"
    end

    "#{base_classes} #{type_classes} border"
  end

  def icon_for_type
    text = case type
    when :success
      "✓"
    when :error
      "✕"
    when :warning
      "⚠"
    when :info
      "ℹ"
    else
      "•"
    end

    color_class = case type
    when :success
      "text-green-600"
    when :error
      "text-red-600"
    when :warning
      "text-yellow-600"
    when :info
      "text-blue-600"
    else
      "text-gray-600"
    end

    %(<span class="#{color_class} font-bold">#{text}</span>).html_safe
  end
end
