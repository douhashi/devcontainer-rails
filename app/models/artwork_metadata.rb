class ArtworkMetadata < ApplicationRecord
  self.table_name = "artwork_metadatas"

  belongs_to :content

  validates :positive_prompt, presence: true
  validates :negative_prompt, presence: true
  validates :content_id, uniqueness: true
end
