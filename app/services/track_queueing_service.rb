class TrackQueueingService
  MAX_TRACKS_PER_CONTENT = 100
  TRACKS_PER_MUSIC_GENERATION = 2

  class ValidationError < StandardError; end

  attr_reader :content

  def initialize(content)
    @content = content
  end

  def self.calculate_track_count(duration)
    return 5 if duration.nil? || duration <= 0

    ((duration.to_f / (3 * 2)) + 5).ceil
  end

  def queue_tracks!
    validate!

    track_count = self.class.calculate_track_count(content.duration)
    music_generation_count = (track_count.to_f / TRACKS_PER_MUSIC_GENERATION).ceil
    music_generations = []

    ActiveRecord::Base.transaction do
      music_generation_count.times do
        music_generation = content.music_generations.create!(
          task_id: "pending-#{SecureRandom.uuid}",
          prompt: content.audio_prompt,
          generation_model: "V4_5PLUS",
          status: :pending
        )
        music_generations << music_generation
        GenerateMusicJob.perform_later(music_generation.id)
      end
    end

    Rails.logger.info "Queued #{music_generation_count} music generations for Content ##{content.id} (expecting #{track_count} tracks)"
    music_generations
  end

  def queue_single_track!
    validate_single_track!

    music_generation = nil

    ActiveRecord::Base.transaction do
      music_generation = content.music_generations.create!(
        task_id: "pending-#{SecureRandom.uuid}",
        prompt: content.audio_prompt,
        generation_model: "V4_5PLUS",
        status: :pending
      )
      GenerateMusicJob.perform_later(music_generation.id)
    end

    Rails.logger.info "Queued MusicGeneration ##{music_generation.id} for Content ##{content.id}"
    music_generation
  end

  private

  def validate!
    raise ValidationError, "Content duration is required" if content.duration.blank?
    raise ValidationError, "Content audio_prompt is required" if content.audio_prompt.blank?
    raise ValidationError, "Content already has tracks being generated" if processing_tracks?

    track_count = self.class.calculate_track_count(content.duration)
    if would_exceed_limit?(track_count)
      raise ValidationError, "Content would exceed maximum track limit (#{MAX_TRACKS_PER_CONTENT})"
    end
  end

  def validate_single_track!
    raise ValidationError, "Content duration is required" if content.duration.blank?
    raise ValidationError, "Content audio_prompt is required" if content.audio_prompt.blank?
    raise ValidationError, "Content already has tracks being generated" if processing_tracks?

    if would_exceed_limit?(1)
      raise ValidationError, "Content would exceed maximum track limit (#{MAX_TRACKS_PER_CONTENT})"
    end
  end

  def processing_tracks?
    content.tracks.exists?(status: :processing)
  end

  def would_exceed_limit?(new_track_count)
    current_count = content.tracks.count
    (current_count + new_track_count) > MAX_TRACKS_PER_CONTENT
  end
end
