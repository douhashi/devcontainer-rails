class MusicGenerationQueueingService
  AVERAGE_TRACK_DURATION_MIN = 3 # 3 minutes per track
  TRACKS_PER_GENERATION = 2 # KIE API returns 2 tracks per generation
  BUFFER_GENERATIONS = 5 # Additional generations as buffer

  def initialize(content)
    @content = content
  end

  def self.calculate_music_generation_count(duration_minutes)
    return 0 if duration_minutes.nil? || duration_minutes <= 0

    # New calculation formula: (duration_min / (3*2)) + 5
    # 3 minutes per track * 2 tracks per generation = 6 minutes per generation
    # Plus 5 generations as buffer
    ((duration_minutes.to_f / (AVERAGE_TRACK_DURATION_MIN * TRACKS_PER_GENERATION)) + BUFFER_GENERATIONS).ceil
  end

  def queue_music_generations!
    generations_to_create = required_music_generation_count - existing_music_generation_count

    # No longer enforce limits - allow generation beyond recommended count
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

  def queue_bulk_generation!(count = nil)
    # Use calculated count as default instead of fixed 5
    count ||= required_music_generation_count
    created_generations = []

    count.times do
      created_generations << create_music_generation
    end

    created_generations
  end

  def required_music_generation_count
    self.class.calculate_music_generation_count(@content.duration_min)
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
