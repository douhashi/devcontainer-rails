# frozen_string_literal: true

class MusicGenerationList::Component < ApplicationViewComponent
  attr_reader :tracks

  def initialize(tracks:)
    @tracks = tracks
  end

  def has_tracks?
    tracks.any?
  end

  def empty_message
    "音楽生成リクエストがありません"
  end

  private

  def music_generation_request_table_component
    MusicGenerationRequestTable::Component.new(
      tracks: tracks,
      show_pagination: false,
      empty_message: empty_message
    )
  end
end
