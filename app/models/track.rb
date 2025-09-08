class Track < ApplicationRecord
  extend Enumerize
  include AudioUploader::Attachment(:audio)

  belongs_to :content
  belongs_to :music_generation, optional: true

  enumerize :status, in: %i[pending processing completed failed], default: :pending, predicates: true

  validates :content, presence: true
  validates :status, presence: true
  validates :duration_sec, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :variant_index, inclusion: { in: [ 0, 1 ] }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { where(status: :pending) }
  scope :processing, -> { where(status: :processing) }
  scope :completed, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }


  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[status created_at music_title content_theme]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[content]
  end

  # Custom ransacker for searching music_title in JSON metadata
  ransacker :music_title, type: :string do
    Arel.sql("json_extract(tracks.metadata, '$.music_title')")
  end

  # Custom ransacker for searching content theme
  ransacker :content_theme, type: :string do
    Arel::Nodes::SqlLiteral.new("contents.theme")
  end

  def generate_audio!
    return false unless status.pending?

    GenerateTrackJob.perform_later(id)
    true
  end

  def formatted_duration
    return "未取得" if duration_sec.nil?

    total_seconds = duration_sec
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
end
