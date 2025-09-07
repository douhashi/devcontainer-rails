class AddDurationToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :duration, :integer
  end
end
