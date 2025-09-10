class YoutubeCredential < ApplicationRecord
  belongs_to :user

  # Enable encryption in production and development environments
  # Test environment is excluded to simplify testing
  unless Rails.env.test?
    encrypts :access_token
    encrypts :refresh_token
  end

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def needs_refresh?
    expires_at <= 5.minutes.from_now
  end

  def update_tokens!(token_data)
    update!(
      access_token: token_data[:access_token],
      refresh_token: token_data[:refresh_token] || refresh_token,
      expires_at: Time.current + token_data[:expires_in].to_i.seconds
    )
  end
end
