class Content < ApplicationRecord
  validates :theme, presence: true, length: { maximum: 256 }
end
