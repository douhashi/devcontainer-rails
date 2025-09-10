class YoutubeService
  extend Dry::Initializer

  option :client_id, default: proc { ENV["YOUTUBE_CLIENT_ID"] }
  option :client_secret, default: proc { ENV["YOUTUBE_CLIENT_SECRET"] }
  option :redirect_uri, default: proc { ENV["YOUTUBE_REDIRECT_URI"] }

  RETRY_DELAY = 1 # seconds
  MAX_RETRIES = 3

  def initialize(**options)
    super

    validate_credentials!
  end

  def authorization_url(scope: "https://www.googleapis.com/auth/youtube.readonly", state: nil)
    with_error_handling do
      # Yt gemでは、scopesは配列で、プレフィックスなしで指定する
      scopes = scope.gsub("https://www.googleapis.com/auth/", "").split(" ")

      account = Yt::Account.new(
        scopes: scopes,
        redirect_uri: redirect_uri,
        force: false
      )

      # authentication_urlメソッドを使用してURLを生成
      url = account.authentication_url

      # stateパラメータを追加（CSRF対策）
      if state.present?
        uri = URI.parse(url)
        params = Rack::Utils.parse_query(uri.query)
        params["state"] = state
        uri.query = params.to_query
        url = uri.to_s
      end

      url
    end
  end

  def authenticate(authorization_code)
    with_error_handling do
      account = Yt::Account.new(
        client_id: client_id,
        client_secret: client_secret,
        redirect_uri: redirect_uri,
        authorization_code: authorization_code
      )

      {
        access_token: account.access_token,
        refresh_token: account.refresh_token,
        expires_in: account.authentication.expires_in
      }
    rescue Yt::Errors::Unauthorized => e
      raise Youtube::Errors::AuthenticationError, "Failed to authenticate with YouTube: #{e.message}"
    end
  end

  def refresh_token!(credential)
    with_error_handling do
      account = Yt::Account.new(
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: credential.refresh_token
      )

      credential.update_tokens!(
        access_token: account.access_token,
        expires_in: account.authentication.expires_in
      )

      true
    rescue Yt::Errors::Unauthorized => e
      Rails.logger.error "Failed to refresh YouTube token: #{e.message}"
      # リフレッシュトークンが無効な場合は、credentialを無効化
      credential.update(invalid: true) if credential.respond_to?(:invalid=)
      raise Youtube::Errors::RefreshTokenError, "Token refresh failed. Please reconnect your YouTube account."
    end
  end

  def authenticated_client(user)
    credential = user.youtube_credential
    raise Youtube::Errors::NotConnectedError, "YouTube account not connected" unless credential

    begin
      refresh_token!(credential) if credential.needs_refresh?
    rescue Youtube::Errors::RefreshTokenError => e
      # リフレッシュが失敗した場合、エラーを再投げして呼び出し元に処理を委ねる
      Rails.logger.error "Failed to refresh token for user #{user.id}: #{e.message}"
      raise
    end

    Yt::Account.new(
      access_token: credential.access_token,
      refresh_token: credential.refresh_token
    )
  end

  def client
    raise Youtube::Errors::AuthenticationError, "Not authenticated. Call authenticate first." unless @authenticated_account
    @authenticated_account
  end

  def get_channel(channel_identifier)
    raise ArgumentError, "Channel identifier cannot be blank" if channel_identifier.blank?

    channel_id = resolve_channel_id(channel_identifier)

    with_error_handling do
      Rails.logger.info "Retrieving YouTube channel information for: #{channel_identifier} (resolved to: #{channel_id})"

      channel = Yt::Channel.new(id: channel_id, api_key: ENV["YOUTUBE_API_KEY"])

      channel_data = {
        title: channel.title,
        description: channel.description,
        subscriber_count: channel.subscriber_count,
        video_count: channel.video_count,
        view_count: channel.view_count
      }

      Rails.logger.info "Successfully retrieved channel information for '#{channel_data[:title]}' (#{channel_data[:subscriber_count]} subscribers)"

      channel_data
    end
  end

  def get_videos(channel_identifier, limit: 50, offset: 0)
    raise ArgumentError, "Channel identifier cannot be blank" if channel_identifier.blank?
    raise ArgumentError, "Limit must be greater than 0" if limit <= 0
    raise ArgumentError, "Offset must be greater than or equal to 0" if offset < 0
    raise ArgumentError, "Limit cannot exceed 1000" if limit > 1000

    channel_id = resolve_channel_id(channel_identifier)

    with_error_handling do
      Rails.logger.info "Retrieving videos for channel: #{channel_identifier} (resolved to: #{channel_id}) with limit: #{limit}, offset: #{offset}"

      channel = Yt::Channel.new(id: channel_id, api_key: ENV["YOUTUBE_API_KEY"])
      videos_collection = channel.videos

      # Apply offset and limit using yt gem's drop/take methods
      videos_collection = videos_collection.drop(offset) if offset > 0
      raw_videos = videos_collection.take(limit)

      # Process videos and filter out any that can't be accessed
      processed_videos = []
      raw_videos.each do |video|
        begin
          video_data = extract_video_data(video)
          processed_videos << video_data if video_data
        rescue StandardError => e
          Rails.logger.warn "Skipping video due to error: #{e.message}"
          next
        end
      end

      result = {
        videos: processed_videos,
        pagination: {
          limit: limit,
          offset: offset,
          returned_count: processed_videos.size
        }
      }

      Rails.logger.info "Successfully retrieved #{processed_videos.size} videos from channel"

      result
    end
  end

  def self.test_connection(channel_identifier = "UC_x5XG1OV2P6uZZ5FSM9Ttw")
    Rails.logger.info "Testing YouTube channel connection for: #{channel_identifier}"

    service = new
    service.get_channel(channel_identifier)
  end

  private

  def extract_video_data(video)
    {
      id: video.id,
      title: video.title,
      description: video.description,
      published_at: video.published_at,
      view_count: video.view_count,
      like_count: video.like_count,
      duration: video.duration,
      thumbnail_url: video.respond_to?(:thumbnail_url) ? video.thumbnail_url : nil
    }
  end

  def validate_credentials!
    missing_credentials = []
    missing_credentials << "YOUTUBE_CLIENT_ID" if client_id.nil? || client_id.empty?
    missing_credentials << "YOUTUBE_CLIENT_SECRET" if client_secret.nil? || client_secret.empty?
    missing_credentials << "YOUTUBE_REDIRECT_URI" if redirect_uri.nil? || redirect_uri.empty?

    return if missing_credentials.empty?

    error_message = "Missing required YouTube API credentials: #{missing_credentials.join(', ')}"
    raise Youtube::Errors::AuthenticationError, error_message
  end

  def with_error_handling(&block)
    retries = 0

    begin
      yield
    rescue Yt::Errors::RequestError => e
      # yt gem's RequestError doesn't have status_code directly
      # We need to inspect the response_body or reasons for error type
      error_reasons = e.reasons || []
      error_message = e.message.to_s

      # First, check if this is a rate limit error and handle retry logic
      if is_rate_limit_error?(error_reasons, error_message)
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.info "Retrying after rate limit: #{error_message} (attempt #{retries + 1}/#{MAX_RETRIES})"
          sleep(RETRY_DELAY * (2 ** retries)) # Exponential backoff
          retry
        else
          raise Youtube::Errors::RateLimitError.new(
            "YouTube API rate limit exceeded: #{error_message}",
            nil,
            e.response_body
          )
        end
      elsif is_auth_error?(error_reasons, error_message)
        raise Youtube::Errors::AuthenticationError.new(
          "YouTube authentication failed: #{error_message}",
          nil,
          e.response_body
        )
      elsif is_quota_error?(error_reasons, error_message)
        raise Youtube::Errors::QuotaExceededError.new(
          "YouTube API quota exceeded: #{error_message}",
          nil,
          e.response_body
        )
      elsif is_not_found_error?(error_reasons, error_message)
        raise Youtube::Errors::NotFoundError.new(
          "YouTube resource not found: #{error_message}",
          nil,
          e.response_body
        )
      else
        raise Youtube::Errors::ApiError.new(
          "YouTube API error: #{error_message}",
          nil,
          e.response_body
        )
      end
    rescue StandardError => e
      # Handle custom error objects (like test doubles) that have reasons and response_body methods
      if e.respond_to?(:reasons) && e.respond_to?(:response_body)
        error_reasons = e.reasons || []
        error_message = e.message.to_s

        # Apply the same error classification logic for custom errors
        if is_rate_limit_error?(error_reasons, error_message)
          retries += 1
          if retries <= MAX_RETRIES
            Rails.logger.info "Retrying after rate limit: #{error_message} (attempt #{retries + 1}/#{MAX_RETRIES})"
            sleep(RETRY_DELAY * (2 ** retries)) # Exponential backoff
            retry
          else
            raise Youtube::Errors::RateLimitError.new(
              "YouTube API rate limit exceeded: #{error_message}",
              nil,
              e.response_body
            )
          end
        elsif is_auth_error?(error_reasons, error_message)
          raise Youtube::Errors::AuthenticationError.new(
            "YouTube authentication failed: #{error_message}",
            nil,
            e.response_body
          )
        elsif is_quota_error?(error_reasons, error_message)
          raise Youtube::Errors::QuotaExceededError.new(
            "YouTube API quota exceeded: #{error_message}",
            nil,
            e.response_body
          )
        elsif is_not_found_error?(error_reasons, error_message)
          raise Youtube::Errors::NotFoundError.new(
            "YouTube resource not found: #{error_message}",
            nil,
            e.response_body
          )
        else
          raise Youtube::Errors::ApiError.new(
            "YouTube API error: #{error_message}",
            nil,
            e.response_body
          )
        end
      else
        raise Youtube::Errors::ApiError, "Unexpected error: #{e.message}"
      end
    end
  end

  def is_rate_limit_error?(reasons, message)
    (reasons.is_a?(Array) && reasons.include?("rateLimitExceeded")) ||
    message.downcase.include?("rate limit")
  end

  def is_auth_error?(reasons, message)
    (reasons.is_a?(Array) && reasons.include?("authError")) ||
    message.downcase.include?("authentication") ||
    message.downcase.include?("auth")
  end

  def is_quota_error?(reasons, message)
    (reasons.is_a?(Array) && reasons.include?("quotaExceeded")) ||
    message.downcase.include?("quota")
  end

  def is_not_found_error?(reasons, message)
    (reasons.is_a?(Array) && reasons.include?("notFound")) ||
    message.downcase.include?("not found")
  end

  def resolve_channel_id(channel_identifier)
    # Only accept channel IDs that start with 'UC'
    if channel_identifier.start_with?("UC")
      return channel_identifier
    end

    # Reject handles and other formats for simplicity
    raise ArgumentError, "Invalid channel identifier: '#{channel_identifier}'. Only YouTube channel IDs starting with 'UC' are supported."
  end
end
