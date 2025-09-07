class Track < ApplicationRecord
  extend Enumerize
  include AudioUploader::Attachment(:audio)

  belongs_to :content

  enumerize :status, in: %i[pending processing completed failed], default: :pending, predicates: true

  validates :content, presence: true
  validates :status, presence: true
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { where(status: :pending) }
  scope :processing, -> { where(status: :processing) }
  scope :completed, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }

  def generate_audio!
    return false unless status.pending?

    GenerateTrackJob.perform_later(id)
    true
  end

  def formatted_duration
    return "未取得" if duration.nil?

    total_seconds = duration
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60

    if hours > 0
      format("%d:%02d:%02d", hours, minutes, seconds)
    else
      format("%d:%02d", minutes, seconds)
    end
  end
end
