class AddAudioDataToAudios < ActiveRecord::Migration[8.0]
  def change
    add_column :audios, :audio_data, :text
  end
end
