# frozen_string_literal: true

class MusicGenerationList::Component < ApplicationViewComponent
  attr_reader :music_generations

  def initialize(music_generations:)
    @music_generations = music_generations
  end

  def has_generations?
    music_generations.any?
  end

  def empty_message
    "音楽生成リクエストがありません"
  end

  private

  def music_generation_table_component
    MusicGenerationTable::Component.new(
      music_generations: music_generations,
      show_pagination: false,
      empty_message: empty_message
    )
  end
end
