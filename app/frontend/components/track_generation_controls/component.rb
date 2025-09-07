# frozen_string_literal: true

class TrackGenerationControls::Component < ApplicationViewComponent
  include Rails.application.routes.url_helpers

  attr_reader :content_record, :can_generate_more

  def initialize(content_record:, can_generate_more: true)
    @content_record = content_record
    @can_generate_more = can_generate_more
  end

  def single_generation_path
    generate_single_content_tracks_path(content_record)
  end

  def bulk_generation_path
    generate_bulk_content_tracks_path(content_record)
  end

  def button_disabled_class
    can_generate_more ? "" : "opacity-50 cursor-not-allowed"
  end

  def single_button_classes
    base = "px-6 py-3 text-white font-medium rounded-lg transition-all duration-200 flex items-center space-x-2"
    color = can_generate_more ? "bg-blue-600 hover:bg-blue-700" : "bg-gray-400"
    "#{base} #{color} #{button_disabled_class}"
  end

  def bulk_button_classes
    base = "px-6 py-3 text-white font-medium rounded-lg transition-all duration-200 flex items-center space-x-2"
    color = can_generate_more ? "bg-green-600 hover:bg-green-700" : "bg-gray-400"
    "#{base} #{color} #{button_disabled_class}"
  end
end
