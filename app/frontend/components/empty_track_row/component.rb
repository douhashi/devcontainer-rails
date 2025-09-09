# frozen_string_literal: true

class EmptyTrackRow::Component < ApplicationViewComponent
  attr_reader :music_generation

  def initialize(music_generation:)
    @music_generation = music_generation
  end

  private

  def music_generation_id
    music_generation.id
  end
end
