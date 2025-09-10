require "yt"

Yt.configure do |config|
  config.client_id = ENV["YOUTUBE_CLIENT_ID"]
  config.client_secret = ENV["YOUTUBE_CLIENT_SECRET"]
  config.api_key = ENV["YOUTUBE_API_KEY"] if ENV["YOUTUBE_API_KEY"].present?

  # Development環境では詳細ログを有効化
  if Rails.env.development?
    config.log_level = :debug
  end
end
