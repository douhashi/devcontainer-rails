class AddAudioDataToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :audio_data, :json
  end
end
