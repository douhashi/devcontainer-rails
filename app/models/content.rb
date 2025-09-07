class Content < ApplicationRecord
  has_many :tracks, dependent: :destroy
  has_one :artwork, dependent: :destroy

  validates :theme, presence: true, length: { maximum: 256 }
  validates :duration, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 60 }
  validates :audio_prompt, presence: true, length: { maximum: 1000 }
end
