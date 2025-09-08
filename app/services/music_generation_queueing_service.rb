class MusicGenerationQueueingService
  AVERAGE_TRACK_DURATION = 240 # seconds per track (4 minutes)
  TRACKS_PER_GENERATION = 2 # KIE API returns 2 tracks per generation

  def initialize(content)
    @content = content
  end

  def self.calculate_music_generation_count(duration_seconds)
    # Each generation produces 2 tracks of ~240 seconds each = 480 seconds total
    total_duration_per_generation = AVERAGE_TRACK_DURATION * TRACKS_PER_GENERATION

    # Calculate required generations (round up)
    (duration_seconds.to_f / total_duration_per_generation).ceil
  end

  def queue_music_generations!
    generations_to_create = required_music_generation_count - existing_music_generation_count

    return [] if generations_to_create <= 0

    created_generations = []

    generations_to_create.times do
      created_generations << create_music_generation
    end

    created_generations
  end

  def queue_single_generation!
    create_music_generation
  end

  def queue_bulk_generation!(count = 5)
    created_generations = []

    count.times do
      created_generations << create_music_generation
    end

    created_generations
  end

  def required_music_generation_count
    self.class.calculate_music_generation_count(@content.duration)
  end

  def existing_music_generation_count
    @content.music_generations.count
  end

  private

  def create_music_generation
    music_generation = @content.music_generations.create!(
      task_id: "pending_#{SecureRandom.hex(16)}",
      status: :pending,
      prompt: @content.audio_prompt,
      generation_model: "V4_5PLUS"
    )

    GenerateMusicGenerationJob.perform_later(music_generation.id)
    music_generation
  end
end
