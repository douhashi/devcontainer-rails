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

  after_update :broadcast_status_update_if_changed
  after_update :broadcast_completion_notification_if_finished

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

  def broadcast_status_update
    ActionCable.server.broadcast(
      "content_#{content_id}_tracks",
      {
        action: "replace",
        target: "track_#{id}",
        html: ApplicationController.render(
          partial: "tracks/track",
          locals: { track: self, track_counter: content.tracks.index(self) + 1 }
        )
      }
    )
  end

  def broadcast_completion_notification
    return unless status.completed? || status.failed?

    message = status.completed? ? "Track生成が完了しました" : "Track生成に失敗しました"
    type = status.completed? ? "success" : "error"

    ActionCable.server.broadcast(
      "content_#{content_id}_notifications",
      {
        action: "append",
        target: "notifications",
        html: ApplicationController.render(
          partial: "shared/toast",
          locals: { message: message, type: type }
        )
      }
    )
  end

  private

  def broadcast_status_update_if_changed
    broadcast_status_update if saved_change_to_status?
  end

  def broadcast_completion_notification_if_finished
    broadcast_completion_notification if saved_change_to_status? && (status.completed? || status.failed?)
  end
end
