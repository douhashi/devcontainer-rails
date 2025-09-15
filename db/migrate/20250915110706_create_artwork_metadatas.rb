class CreateArtworkMetadatas < ActiveRecord::Migration[8.0]
  def change
    create_table :artwork_metadatas do |t|
      t.references :content, null: false, foreign_key: true, index: { unique: true }
      t.text :positive_prompt, null: false
      t.text :negative_prompt, null: false

      t.timestamps
    end
  end
end
