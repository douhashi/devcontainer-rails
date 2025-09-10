class Youtube::AuthController < ApplicationController
  before_action :authenticate_user!

  def authorize
    state = generate_state_token
    session[:youtube_oauth_state] = state
    session[:youtube_oauth_state_expires_at] = 10.minutes.from_now.to_i
    redirect_to youtube_service.authorization_url(state: state), allow_other_host: true
  end

  def callback
    if params[:error] == "access_denied"
      redirect_to root_path, alert: t(".cancelled")
      return
    end

    # Verify state parameter for CSRF protection
    if params[:state] != session[:youtube_oauth_state]
      Rails.logger.error "Invalid state parameter in YouTube OAuth callback"
      redirect_to root_path, alert: t(".error")
      return
    end

    # Check state token expiration
    if session[:youtube_oauth_state_expires_at] && Time.current.to_i > session[:youtube_oauth_state_expires_at]
      Rails.logger.error "Expired state token in YouTube OAuth callback"
      redirect_to root_path, alert: t(".expired")
      return
    end

    begin
      token_data = youtube_service.authenticate(params[:code])
      save_credentials(token_data)
      redirect_to root_path, notice: t(".success")
    rescue Youtube::Errors::AuthenticationError => e
      Rails.logger.error "YouTube authentication error: #{e.message}"
      redirect_to root_path, alert: t(".error")
    ensure
      session.delete(:youtube_oauth_state)
      session.delete(:youtube_oauth_state_expires_at)
    end
  end

  def disconnect
    if current_user.youtube_credential&.destroy
      redirect_to root_path, notice: t(".success")
    else
      redirect_to root_path, alert: t(".not_connected")
    end
  end

  private

  def youtube_service
    @youtube_service ||= YoutubeService.new
  end

  def save_credentials(token_data)
    if current_user.youtube_credential
      current_user.youtube_credential.update_tokens!(token_data)
    else
      current_user.create_youtube_credential!(
        access_token: token_data[:access_token],
        refresh_token: token_data[:refresh_token],
        expires_at: Time.current + token_data[:expires_in].to_i.seconds,
        scope: token_data[:scope] || "youtube.readonly yt-analytics.readonly"
      )
    end
  end

  def generate_state_token
    SecureRandom.urlsafe_base64(32)
  end
end
