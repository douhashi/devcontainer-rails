class CreateYoutubeCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :youtube_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :expires_at, null: false
      t.string :scope

      t.timestamps
    end
  end
end
