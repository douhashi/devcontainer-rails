class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.references :content, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :tracks, :status
  end
end
