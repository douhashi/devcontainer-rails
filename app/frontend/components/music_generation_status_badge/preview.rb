# frozen_string_literal: true

class MusicGenerationStatusBadge::Preview < ApplicationViewComponentPreview
  def pending
    music_generation = MusicGeneration.new(
      id: 1,
      status: :pending,
      task_id: "task_123",
      prompt: "Create a lo-fi hip hop beat",
      generation_model: "V4_5PLUS"
    )
    render(MusicGenerationStatusBadge::Component.new(music_generation: music_generation))
  end

  def processing
    music_generation = MusicGeneration.new(
      id: 2,
      status: :processing,
      task_id: "task_456",
      prompt: "Create a lo-fi hip hop beat",
      generation_model: "V4_5PLUS"
    )
    render(MusicGenerationStatusBadge::Component.new(music_generation: music_generation))
  end

  def completed
    music_generation = MusicGeneration.new(
      id: 3,
      status: :completed,
      task_id: "task_789",
      prompt: "Create a lo-fi hip hop beat",
      generation_model: "V4_5PLUS"
    )
    render(MusicGenerationStatusBadge::Component.new(music_generation: music_generation))
  end

  def failed
    music_generation = MusicGeneration.new(
      id: 4,
      status: :failed,
      task_id: "task_000",
      prompt: "Create a lo-fi hip hop beat",
      generation_model: "V4_5PLUS"
    )
    render(MusicGenerationStatusBadge::Component.new(music_generation: music_generation))
  end

  def all_statuses
    render_with_template(template: "music_generation_status_badge/preview/all_statuses")
  end
end
