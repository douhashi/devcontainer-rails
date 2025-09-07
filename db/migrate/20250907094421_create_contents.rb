class CreateContents < ActiveRecord::Migration[8.0]
  def change
    create_table :contents do |t|
      t.string :theme, null: false, limit: 256

      t.timestamps
    end

    add_index :contents, :theme
  end
end
