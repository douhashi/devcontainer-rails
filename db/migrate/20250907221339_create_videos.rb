class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.references :content, null: false, foreign_key: true, index: true
      t.string :status, null: false, default: 'pending'
      t.text :video_data
      t.string :resolution
      t.integer :file_size
      t.integer :duration_seconds
      t.text :error_message

      t.timestamps
    end

    add_index :videos, :status
  end
end
