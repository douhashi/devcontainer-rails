class Artwork < ApplicationRecord
  include ImageUploader::Attachment(:image)

  belongs_to :content

  validates :image, presence: true
end
