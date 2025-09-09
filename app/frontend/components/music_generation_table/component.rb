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

  def music_generation_row_component(music_generation)
    MusicGenerationRow::Component.new(music_generation: music_generation)
  end
end
