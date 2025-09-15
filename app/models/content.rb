class Content < ApplicationRecord
  has_many :tracks, dependent: :destroy
  has_many :music_generations, dependent: :destroy
  has_one :artwork, dependent: :destroy
  has_one :audio, dependent: :destroy
  has_one :video, dependent: :destroy
  has_one :youtube_metadata, dependent: :destroy
  has_one :artwork_metadata, dependent: :destroy

  validates :theme, presence: true, length: { maximum: 256 }
  validates :duration_min, presence: true, numericality: { greater_than: 0 }
  validates :audio_prompt, presence: true, length: { maximum: 1000 }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[theme created_at]
  end

  def required_track_count
    # Use MusicGenerationQueueingService to calculate based on music generations
    # Each generation produces 2 tracks
    MusicGenerationQueueingService.calculate_music_generation_count(duration_min) * 2
  end

  def track_progress
    completed_count = tracks.completed.count
    total_count = required_track_count
    percentage = total_count > 0 ? (completed_count.to_f / total_count * 100).round(1) : 0.0

    {
      completed: completed_count,
      total: total_count,
      percentage: percentage
    }
  end

  def music_generation_progress
    completed_count = music_generations.completed.count
    total_count = required_music_generation_count
    percentage = total_count > 0 ? (completed_count.to_f / total_count * 100).round(1) : 0.0

    {
      completed: completed_count,
      total: total_count,
      percentage: percentage
    }
  end

  def required_music_generation_count
    MusicGenerationQueueingService.calculate_music_generation_count(duration_min)
  end

  def artwork_status
    artwork.present? ? :configured : :not_configured
  end

  def completion_status
    return :not_started if tracks.count == 0

    if tracks.failed.exists?
      :needs_attention
    elsif tracks.processing.exists?
      :in_progress
    elsif track_progress[:percentage] == 100.0 && artwork_status == :configured
      :completed
    elsif track_progress[:percentage] == 100.0 || tracks.completed.exists?
      :in_progress
    else
      :not_started
    end
  end


  def video_generation_prerequisites_met?
    audio_ready? && artwork_ready?
  end

  def video_generation_missing_prerequisites
    missing = []
    missing << "オーディオが完成していません" unless audio_ready?
    missing << "アートワークが設定されていません" unless artwork_ready?
    missing
  end

  def video_status
    return :not_configured unless video_generation_prerequisites_met?
    return :not_created unless video.present?

    case video.status.to_sym
    when :pending
      :pending
    when :processing
      :processing
    when :completed
      :completed
    when :failed
      :failed
    else
      :unknown
    end
  end

  def tracks_complete?
    return false if tracks.empty?

    total_duration = tracks.completed.sum { |track| track.duration_sec || 0 }
    required_duration = duration_min * 60

    total_duration >= required_duration
  end

  def video_generated?
    video.present? && video.completed?
  end

  def youtube_metadata_status
    youtube_metadata.present? ? :configured : :not_configured
  end

  def artwork_metadata_status
    artwork_metadata.present? ? :configured : :not_configured
  end

  private

  def audio_ready?
    audio.present? && audio.completed?
  end

  def artwork_ready?
    artwork.present?
  end
end
