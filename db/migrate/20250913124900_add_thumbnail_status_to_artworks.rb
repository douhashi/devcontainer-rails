class AddThumbnailStatusToArtworks < ActiveRecord::Migration[8.0]
  def change
    add_column :artworks, :thumbnail_generation_status, :integer, default: 0, null: false
    add_column :artworks, :thumbnail_generation_error, :text
    add_column :artworks, :thumbnail_generated_at, :datetime

    add_index :artworks, :thumbnail_generation_status
  end
end
