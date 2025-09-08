class MusicGeneration < ApplicationRecord
  extend Enumerize

  belongs_to :content
  has_many :tracks, dependent: :destroy

  enumerize :status, in: [ :pending, :processing, :completed, :failed ], default: :pending, predicates: true

  validates :task_id, presence: true, allow_nil: false
  validates :status, presence: true
  validates :prompt, presence: true
  validates :generation_model, presence: true

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }

  def complete!
    update!(status: :completed)
  end

  def fail!
    update!(status: :failed)
  end

  def processing!
    update!(status: :processing)
  end
end
