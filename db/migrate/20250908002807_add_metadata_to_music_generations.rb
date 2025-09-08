class AddMetadataToMusicGenerations < ActiveRecord::Migration[8.0]
  def change
    add_column :music_generations, :metadata, :json, default: {}, null: false
  end
end
