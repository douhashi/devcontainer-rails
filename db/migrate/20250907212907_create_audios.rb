class CreateAudios < ActiveRecord::Migration[8.0]
  def change
    create_table :audios do |t|
      t.references :content, null: false, foreign_key: true
      t.string :status
      t.json :metadata

      t.timestamps
    end
  end
end
