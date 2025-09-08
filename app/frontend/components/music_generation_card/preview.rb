# frozen_string_literal: true

class MusicGenerationCard::Preview < ApplicationViewComponentPreview
  def completed_with_tracks
    content = Content.new(id: 1, theme: "Relaxing Lo-fi", duration_min: 60)
    music_generation = MusicGeneration.new(
      id: 1,
      content: content,
      status: :completed,
      task_id: "task_abc123",
      prompt: "Create a lo-fi hip hop beat with mellow mood",
      generation_model: "V4_5PLUS",
      created_at: 2.hours.ago,
      updated_at: 1.hour.ago
    )

    # Mock tracks
    music_generation.define_singleton_method(:tracks) do
      [
        Track.new(
          id: 1,
          title: "Mellow Beat #1",
          status: :completed,
          duration_sec: 180,
          created_at: 1.hour.ago
        ),
        Track.new(
          id: 2,
          title: "Mellow Beat #2",
          status: :completed,
          duration_sec: 185,
          created_at: 1.hour.ago
        )
      ]
    end

    render(MusicGenerationCard::Component.new(music_generation: music_generation))
  end

  def processing
    content = Content.new(id: 2, theme: "Study Music", duration_min: 45)
    music_generation = MusicGeneration.new(
      id: 2,
      content: content,
      status: :processing,
      task_id: "task_def456",
      prompt: "Create calm study music with piano",
      generation_model: "V4_5PLUS",
      created_at: 30.minutes.ago,
      updated_at: 5.minutes.ago
    )

    music_generation.define_singleton_method(:tracks) { [] }

    render(MusicGenerationCard::Component.new(music_generation: music_generation))
  end

  def pending
    content = Content.new(id: 3, theme: "Night Jazz", duration_min: 90)
    music_generation = MusicGeneration.new(
      id: 3,
      content: content,
      status: :pending,
      task_id: "task_ghi789",
      prompt: "Create smooth jazz for night time",
      generation_model: "V4_5PLUS",
      created_at: 10.minutes.ago,
      updated_at: 10.minutes.ago
    )

    music_generation.define_singleton_method(:tracks) { [] }

    render(MusicGenerationCard::Component.new(music_generation: music_generation))
  end

  def failed
    content = Content.new(id: 4, theme: "Ambient Sounds", duration_min: 30)
    music_generation = MusicGeneration.new(
      id: 4,
      content: content,
      status: :failed,
      task_id: "task_jkl012",
      prompt: "Create ambient soundscape",
      generation_model: "V4_5PLUS",
      created_at: 3.hours.ago,
      updated_at: 2.hours.ago
    )

    music_generation.define_singleton_method(:tracks) { [] }

    render(MusicGenerationCard::Component.new(music_generation: music_generation))
  end
end
