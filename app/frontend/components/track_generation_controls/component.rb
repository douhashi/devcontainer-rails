# frozen_string_literal: true

class TrackGenerationControls::Component < ApplicationViewComponent
  include Rails.application.routes.url_helpers

  attr_reader :content_record, :can_generate_more

  def initialize(content_record:, can_generate_more: true)
    @content_record = content_record
    @can_generate_more = true  # Always allow generation
  end

  def single_generation_path
    generate_single_content_tracks_path(content_record)
  end

  def bulk_generation_path
    generate_bulk_content_tracks_path(content_record)
  end

  def button_disabled_class
    ""  # Never disabled
  end

  def single_button_classes
    base = "px-6 py-3 text-white font-medium rounded-lg transition-all duration-200 flex items-center space-x-2"
    color = "bg-blue-600 hover:bg-blue-700"  # Always active color
    "#{base} #{color}"
  end

  def bulk_button_classes
    base = "px-6 py-3 text-white font-medium rounded-lg transition-all duration-200 flex items-center space-x-2"
    color = "bg-green-600 hover:bg-green-700"  # Always active color
    "#{base} #{color}"
  end

  def required_music_generation_count
    MusicGenerationQueueingService.calculate_music_generation_count(content_record.duration_min)
  end

  def required_track_count
    required_music_generation_count * MusicGenerationQueueingService::TRACKS_PER_GENERATION
  end
end
