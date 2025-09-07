class Content < ApplicationRecord
  has_many :tracks, dependent: :destroy

  validates :theme, presence: true, length: { maximum: 256 }
end
