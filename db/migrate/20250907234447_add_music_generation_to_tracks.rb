class AddMusicGenerationToTracks < ActiveRecord::Migration[8.0]
  def up
    # Add columns with null: true first for existing data
    add_reference :tracks, :music_generation, null: true, foreign_key: true
    add_column :tracks, :variant_index, :integer

    # Create dummy MusicGeneration records for existing tracks
    Track.find_each do |track|
      next if track.music_generation_id.present?

      music_generation = MusicGeneration.create!(
        content_id: track.content_id,
        task_id: track.metadata&.dig('task_id') || "legacy_#{SecureRandom.hex(8)}",
        status: track.status,
        prompt: track.content.audio_prompt,
        generation_model: track.metadata&.dig('model_name') || 'chirp-v3-5',
        api_response: nil,
        created_at: track.created_at,
        updated_at: track.updated_at
      )

      track.update_columns(
        music_generation_id: music_generation.id,
        variant_index: 0
      )
    end

    # Now make the music_generation_id column non-nullable
    # Note: We keep it nullable for gradual migration as mentioned in the plan
    # change_column_null :tracks, :music_generation_id, false
  end

  def down
    remove_column :tracks, :variant_index
    remove_reference :tracks, :music_generation, foreign_key: true
  end
end
