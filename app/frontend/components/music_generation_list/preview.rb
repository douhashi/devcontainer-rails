# frozen_string_literal: true

class MusicGenerationList::Preview < ApplicationViewComponentPreview
  def with_multiple_generations
    content = Content.new(id: 1, theme: "Relaxing Lo-fi", duration_min: 60)

    generations = [
      create_mock_generation(1, content, :completed, 3.hours.ago, with_tracks: true),
      create_mock_generation(2, content, :processing, 1.hour.ago),
      create_mock_generation(3, content, :pending, 30.minutes.ago),
      create_mock_generation(4, content, :failed, 2.hours.ago)
    ]

    render(MusicGenerationList::Component.new(music_generations: generations))
  end

  def empty_list
    render(MusicGenerationList::Component.new(music_generations: []))
  end

  def single_generation
    content = Content.new(id: 2, theme: "Study Music", duration_min: 45)
    generation = create_mock_generation(1, content, :completed, 1.hour.ago, with_tracks: true)

    render(MusicGenerationList::Component.new(music_generations: [ generation ]))
  end

  private

  def create_mock_generation(id, content, status, created_at, with_tracks: false)
    generation = MusicGeneration.new(
      id: id,
      content: content,
      status: status,
      task_id: "task_#{SecureRandom.hex(6)}",
      prompt: "Create a #{status} music generation",
      generation_model: "V4_5PLUS",
      created_at: created_at,
      updated_at: created_at + 10.minutes
    )

    if with_tracks
      generation.define_singleton_method(:tracks) do
        [
          Track.new(
            id: id * 10 + 1,
            title: "Track ##{id * 10 + 1}",
            status: :completed,
            duration_sec: 180,
            created_at: created_at + 30.minutes
          ),
          Track.new(
            id: id * 10 + 2,
            title: "Track ##{id * 10 + 2}",
            status: :completed,
            duration_sec: 185,
            created_at: created_at + 35.minutes
          )
        ]
      end
    else
      generation.define_singleton_method(:tracks) { [] }
    end

    generation
  end
end
