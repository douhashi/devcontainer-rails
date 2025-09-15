class CreateYoutubeMetadatas < ActiveRecord::Migration[8.0]
  def change
    create_table :youtube_metadatas do |t|
      t.references :content, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false, limit: 100
      t.text :description_en, null: false, limit: 5000
      t.text :description_ja, null: false, limit: 5000
      t.string :hashtags, limit: 500
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :youtube_metadatas, :status
  end
end
