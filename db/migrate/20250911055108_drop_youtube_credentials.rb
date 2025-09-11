class DropYoutubeCredentials < ActiveRecord::Migration[8.0]
  def change
    drop_table :youtube_credentials
  end
end
