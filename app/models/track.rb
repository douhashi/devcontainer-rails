class Track < ApplicationRecord
  extend Enumerize
  include AudioUploader::Attachment(:audio)

  belongs_to :content
  belongs_to :music_generation, optional: true

  enumerize :status, in: %i[pending processing completed failed], default: :pending, predicates: true

  validates :content, presence: true
  validates :status, presence: true
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :variant_index, inclusion: { in: [ 0, 1 ] }, allow_nil: true

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

  def metadata_title
    metadata&.dig("music_title")
  end

  def metadata_tags
    metadata&.dig("music_tags")
  end

  def metadata_model_name
    metadata&.dig("model_name")
  end

  def metadata_generated_prompt
    metadata&.dig("generated_prompt")
  end

  def metadata_audio_id
    metadata&.dig("audio_id")
  end

  def has_metadata?
    return false if metadata.nil? || metadata.empty?

    %w[music_title music_tags model_name generated_prompt audio_id].any? do |key|
      metadata[key].present?
    end
  end

  def broadcast_status_update
    # Skip broadcasting in test environment to avoid rendering issues
    return if Rails.env.test?

    Rails.logger.info "Track ##{id}: Broadcasting status update to content_#{content_id}_tracks"

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

    Rails.logger.info "Track ##{id}: Successfully broadcasted status update for status: #{status}"
  end

  def broadcast_completion_notification
    return unless status.completed? || status.failed?

    # Skip broadcasting in test environment to avoid rendering issues
    return if Rails.env.test?

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
    if saved_change_to_status?
      Rails.logger.info "Track ##{id}: Status changed from #{saved_change_to_status[0]} to #{saved_change_to_status[1]}"
      broadcast_status_update
    else
      Rails.logger.debug "Track ##{id}: No status change detected, skipping broadcast"
    end
  end

  def broadcast_completion_notification_if_finished
    broadcast_completion_notification if saved_change_to_status? && (status.completed? || status.failed?)
  end
end
