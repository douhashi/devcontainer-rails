class Content < ApplicationRecord
  has_many :tracks, dependent: :destroy
  has_one :artwork, dependent: :destroy

  validates :theme, presence: true, length: { maximum: 256 }
  validates :duration, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 60 }
  validates :audio_prompt, presence: true, length: { maximum: 1000 }

  def required_track_count
    TrackQueueingService.calculate_track_count(duration)
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

  def next_actions
    actions = []

    if tracks.count < required_track_count
      actions << "トラックを生成してください"
    end

    if tracks.failed.exists?
      actions << "失敗したトラックを再生成してください"
    end

    if artwork_status == :not_configured
      actions << "アートワークを設定してください"
    end

    actions
  end
end
