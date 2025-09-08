class CreateMusicGenerations < ActiveRecord::Migration[8.0]
  def change
    create_table :music_generations do |t|
      t.references :content, null: false, foreign_key: true
      t.string :task_id, null: false
      t.string :status, null: false
      t.text :prompt, null: false
      t.string :generation_model, null: false
      t.json :api_response

      t.timestamps
    end

    add_index :music_generations, :task_id
    add_index :music_generations, :status
  end
end
