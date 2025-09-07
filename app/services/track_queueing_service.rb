class TrackQueueingService
  MAX_TRACKS_PER_CONTENT = 100

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
    tracks = []

    ActiveRecord::Base.transaction do
      track_count.times do
        tracks << content.tracks.create!(status: :pending)
      end

      tracks.each do |track|
        GenerateTrackJob.perform_later(track.id)
      end
    end

    Rails.logger.info "Queued #{track_count} tracks for Content ##{content.id}"
    tracks
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

  def processing_tracks?
    content.tracks.exists?(status: :processing)
  end

  def would_exceed_limit?(new_track_count)
    current_count = content.tracks.count
    (current_count + new_track_count) > MAX_TRACKS_PER_CONTENT
  end
end
