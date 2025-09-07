class CreateArtworks < ActiveRecord::Migration[8.0]
  def change
    create_table :artworks do |t|
      t.references :content, null: false, foreign_key: true
      t.json :image_data

      t.timestamps
    end
  end
end
