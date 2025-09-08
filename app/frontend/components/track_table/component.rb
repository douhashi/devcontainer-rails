# frozen_string_literal: true

class TrackTable::Component < ApplicationViewComponent
  attr_reader :tracks, :show_pagination, :show_content_column, :empty_message

  def initialize(tracks:, show_pagination: true, show_content_column: true, empty_message: "データがありません")
    @tracks = tracks
    @show_pagination = show_pagination
    @show_content_column = show_content_column
    @empty_message = empty_message
  end

  private

  def has_tracks?
    tracks.any?
  end

  def show_pagination_area?
    show_pagination && tracks.respond_to?(:current_page)
  end

  def track_row_component(track)
    TrackRow::Component.new(track: track, show_content_column: show_content_column)
  end
end
