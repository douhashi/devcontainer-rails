# frozen_string_literal: true

class MusicGenerationRow::Preview < ViewComponent::Preview
  def completed_with_tracks
    content = Content.create!(
      theme: "Relaxing Lo-Fi",
      duration_min: 60,
      audio_prompt: "Peaceful lo-fi music for relaxation"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Create peaceful lo-fi beats",
      task_id: "task_completed_001",
      generation_model: "kie-ai-v2",
      status: :completed
    )

    # Create tracks with duration
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Morning Vibes" },
      duration_sec: 180,
      status: :completed
    )
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Afternoon Flow" },
      duration_sec: 240,
      status: :completed
    )

    render_row_in_table(music_generation)
  end

  def processing_status
    content = Content.create!(
      theme: "Study Focus",
      duration_min: 45,
      audio_prompt: "Background music for concentration"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Generate focus music",
      task_id: "task_processing_001",
      generation_model: "kie-ai-v2",
      status: :processing
    )

    render_row_in_table(music_generation)
  end

  def pending_status
    content = Content.create!(
      theme: "Workout Beats",
      duration_min: 30,
      audio_prompt: "High-energy beats for workouts"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Create energetic workout music",
      task_id: "task_pending_001",
      generation_model: "kie-ai-v2",
      status: :pending
    )

    render_row_in_table(music_generation)
  end

  def failed_status
    content = Content.create!(
      theme: "Meditation Music",
      duration_min: 20,
      audio_prompt: "Calming music for meditation"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Generate meditation sounds",
      task_id: "task_failed_001",
      generation_model: "kie-ai-v2",
      status: :failed
    )

    render_row_in_table(music_generation)
  end

  def without_tracks
    content = Content.create!(
      theme: "Ambient Sounds",
      duration_min: 60,
      audio_prompt: "Natural ambient sounds"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Create natural ambient sounds",
      task_id: "task_no_tracks",
      generation_model: "kie-ai-v2",
      status: :completed
    )

    render_row_in_table(music_generation)
  end

  def long_duration
    content = Content.create!(
      theme: "Extended Mix",
      duration_min: 180,
      audio_prompt: "Long-form ambient music"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Create extended ambient mix",
      task_id: "task_long_duration",
      generation_model: "kie-ai-v2",
      status: :completed
    )

    # Create track with duration over 1 hour
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Extended Ambient Mix" },
      duration_sec: 3665, # 1:01:05
      status: :completed
    )

    render_row_in_table(music_generation)
  end

  private

  def render_row_in_table(music_generation)
    content_tag :table, class: "min-w-full divide-y divide-gray-700 bg-gray-800" do
      content_tag :tbody, class: "bg-gray-800 divide-y divide-gray-700" do
        render MusicGenerationRow::Component.new(music_generation: music_generation)
      end
    end
  end
end
