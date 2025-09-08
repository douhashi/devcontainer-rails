class RenameDurationColumnsWithUnits < ActiveRecord::Migration[8.0]
  def up
    rename_column :contents, :duration, :duration_min
    rename_column :tracks, :duration, :duration_sec
  end

  def down
    rename_column :contents, :duration_min, :duration
    rename_column :tracks, :duration_sec, :duration
  end
end
