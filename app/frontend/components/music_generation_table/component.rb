# frozen_string_literal: true

class MusicGenerationTable::Component < ApplicationViewComponent
  attr_reader :music_generations, :show_pagination, :empty_message

  def initialize(music_generations:, show_pagination: true, empty_message: "音楽生成リクエストがありません")
    @music_generations = music_generations
    @show_pagination = show_pagination
    @empty_message = empty_message
  end

  private

  def has_generations?
    music_generations.any?
  end

  def show_pagination_area?
    show_pagination && music_generations.respond_to?(:current_page)
  end

  def grouped_tracks
    @grouped_tracks ||= build_grouped_tracks
  end

  def build_grouped_tracks
    result = []

    # ActiveRecord_Relationの場合はincludesを使い、Arrayの場合はそのまま処理
    generations = music_generations.respond_to?(:includes) ?
                  music_generations.includes(:tracks) :
                  music_generations

    generations.each do |generation|
      tracks = generation.tracks.order(:created_at)

      if tracks.any?
        tracks.each_with_index do |track, index|
          result << {
            track: track,
            music_generation: generation,
            is_group_start: index == 0,
            group_size: index == 0 ? tracks.size : 0,
            track_number: index + 1  # 作成日時順の連番
          }
        end
      else
        # Trackがない場合の処理
        result << {
          track: nil,
          music_generation: generation,
          is_group_start: true,
          group_size: 1,
          track_number: nil
        }
      end
    end

    result
  end

  def extended_track_row_component(track_data)
    if track_data[:track]
      ExtendedTrackRow::Component.new(
        track: track_data[:track],
        music_generation: track_data[:music_generation],
        is_group_start: track_data[:is_group_start],
        group_size: track_data[:group_size],
        track_number: track_data[:track_number]
      )
    else
      # Trackがない場合のプレースホルダー行を返す
      EmptyTrackRow::Component.new(
        music_generation: track_data[:music_generation]
      )
    end
  end
end
