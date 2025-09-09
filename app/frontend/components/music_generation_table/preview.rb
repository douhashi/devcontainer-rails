# frozen_string_literal: true

class MusicGenerationTable::Preview < ViewComponent::Preview
  def with_music_generations
    content = Content.create!(
      theme: "Relaxing Lo-Fi Music",
      duration_min: 60,
      audio_prompt: "Chill lo-fi hip hop beats with soft piano melodies and rain sounds"
    )

    music_generations = [
      MusicGeneration.create!(
        content: content,
        prompt: "Create peaceful lo-fi beats for studying",
        task_id: "task_completed_001",
        generation_model: "kie-ai-v2",
        status: :completed
      ),
      MusicGeneration.create!(
        content: content,
        prompt: "Generate ambient lo-fi for relaxation",
        task_id: "task_processing_001",
        generation_model: "kie-ai-v2",
        status: :processing
      ),
      MusicGeneration.create!(
        content: content,
        prompt: "Make upbeat lo-fi hip hop",
        task_id: "task_pending_001",
        generation_model: "kie-ai-v2",
        status: :pending
      ),
      MusicGeneration.create!(
        content: content,
        prompt: "Create jazz-influenced lo-fi",
        task_id: "task_failed_001",
        generation_model: "kie-ai-v2",
        status: :failed
      )
    ]

    # Create tracks for completed music generation
    completed_generation = music_generations.first
    Track.create!(
      content: content,
      music_generation: completed_generation,
      metadata: { "music_title" => "Peaceful Study Vibes" },
      duration_sec: 180,
      status: :completed
    )
    Track.create!(
      content: content,
      music_generation: completed_generation,
      metadata: { "music_title" => "Focus Flow" },
      duration_sec: 240,
      status: :completed
    )

    render MusicGenerationTable::Component.new(
      music_generations: MusicGeneration.where(id: music_generations.map(&:id)),
      show_pagination: true
    )
  end

  def with_tracks_various_durations
    content = Content.create!(
      theme: "Study Focus",
      duration_min: 45,
      audio_prompt: "Background music for concentration"
    )

    music_generation = MusicGeneration.create!(
      content: content,
      prompt: "Create background music for deep focus",
      task_id: "task_duration_test",
      generation_model: "kie-ai-v2",
      status: :completed
    )

    # Create tracks with different durations
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Short Track" },
      duration_sec: 65, # 1:05
      status: :completed
    )
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Medium Track" },
      duration_sec: 195, # 3:15
      status: :completed
    )
    Track.create!(
      content: content,
      music_generation: music_generation,
      metadata: { "music_title" => "Long Track" },
      duration_sec: 3665, # 1:01:05 (over 1 hour)
      status: :completed
    )

    render MusicGenerationTable::Component.new(
      music_generations: MusicGeneration.where(id: music_generation.id),
      show_pagination: false
    )
  end

  def empty_state
    render MusicGenerationTable::Component.new(
      music_generations: MusicGeneration.none,
      empty_message: "まだ音楽生成リクエストがありません"
    )
  end

  def without_pagination
    content = Content.create!(
      theme: "Ambient Sounds",
      duration_min: 30,
      audio_prompt: "Gentle ambient sounds for meditation"
    )

    music_generations = [
      MusicGeneration.create!(
        content: content,
        prompt: "Create gentle rain sounds",
        task_id: "task_ambient_001",
        generation_model: "kie-ai-v2",
        status: :completed
      ),
      MusicGeneration.create!(
        content: content,
        prompt: "Generate forest ambience",
        task_id: "task_ambient_002",
        generation_model: "kie-ai-v2",
        status: :completed
      )
    ]

    render MusicGenerationTable::Component.new(
      music_generations: MusicGeneration.where(id: music_generations.map(&:id)),
      show_pagination: false
    )
  end

  def with_pagination
    content = Content.create!(
      theme: "Productive Beats",
      duration_min: 120,
      audio_prompt: "Energetic lo-fi beats for productivity"
    )

    # Create 35 music generations to trigger pagination
    35.times do |i|
      MusicGeneration.create!(
        content: content,
        prompt: "Generate productive music ##{i + 1}",
        task_id: "task_pagination_#{i + 1}",
        generation_model: "kie-ai-v2",
        status: [ :pending, :processing, :completed, :failed ].sample
      )
    end

    render MusicGenerationTable::Component.new(
      music_generations: MusicGeneration.where(content: content).page(1),
      show_pagination: true
    )
  end
end
