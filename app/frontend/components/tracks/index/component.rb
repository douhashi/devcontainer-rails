# frozen_string_literal: true

class Tracks::Index::Component < ApplicationViewComponent
  attr_reader :tracks

  def initialize(tracks:)
    @tracks = tracks
  end

  private

  def empty_state?
    tracks.empty?
  end

  def paginated?
    tracks.respond_to?(:current_page)
  end

  def total_count
    if paginated?
      tracks.total_count
    else
      tracks.size
    end
  end

  def page_summary_text
    return "0件のTrack" if total_count == 0

    if paginated?
      start_item = (tracks.current_page - 1) * tracks.limit_value + 1
      end_item = [ start_item + tracks.size - 1, total_count ].min
      "#{total_count}件中 #{start_item}-#{end_item}件を表示"
    else
      "#{total_count}件のTrack"
    end
  end
end
