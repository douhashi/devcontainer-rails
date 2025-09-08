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

  def music_generation_card_component(music_generation)
    MusicGenerationCard::Component.new(music_generation: music_generation)
  end
end
