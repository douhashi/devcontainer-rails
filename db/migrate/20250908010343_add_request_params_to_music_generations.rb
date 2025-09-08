class AddRequestParamsToMusicGenerations < ActiveRecord::Migration[8.0]
  def change
    add_column :music_generations, :request_params, :json, default: {}
  end
end
