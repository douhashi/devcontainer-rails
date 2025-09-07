class Track < ApplicationRecord
  extend Enumerize
  include AudioUploader::Attachment(:audio)

  belongs_to :content

  enumerize :status, in: %i[pending processing completed failed], default: :pending, predicates: true

  validates :content, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
end
