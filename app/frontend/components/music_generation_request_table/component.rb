# frozen_string_literal: true

class MusicGenerationRequestTable::Component < ApplicationViewComponent
  attr_reader :tracks, :show_pagination, :empty_message

  def initialize(tracks:, show_pagination: true, empty_message: "音楽生成リクエストがありません")
    @tracks = tracks
    @show_pagination = show_pagination
    @empty_message = empty_message
  end

  private

  def has_tracks?
    tracks.any?
  end

  def show_pagination_area?
    show_pagination && tracks.respond_to?(:current_page)
  end

  def track_row_data
    tracks.each_with_index.map do |track, index|
      {
        track: track,
        track_number: index + 1
      }
    end
  end

  def track_request_row_component(row_data)
    TrackRequestRow::Component.new(
      track: row_data[:track],
      track_number: row_data[:track_number]
    )
  end
end
