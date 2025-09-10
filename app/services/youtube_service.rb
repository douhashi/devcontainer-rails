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
      client = Yt::Account.new
      client.authorization_url(
        scope: scope,
        redirect_uri: redirect_uri,
        state: state
      )
    end
  end

  def authenticate(authorization_code:)
    with_error_handling do
      account = Yt::Account.new
      account.authenticate!(
        code: authorization_code,
        redirect_uri: redirect_uri
      )
      @authenticated_account = account
      account
    end
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

  def self.test_connection(channel_identifier = "@LofiBGM-111")
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
      thumbnail_url: video.thumbnails&.default&.url
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
    # If it's already a channel ID (starts with UC), return as is
    return channel_identifier if channel_identifier.start_with?("UC")

    # Handle known channel mappings
    known_channels = {
      "@LofiBGM-111" => "UCxYJQNWjcK7pK5JLNfHsz6w"  # Placeholder - would need actual channel ID
    }

    if known_channels.key?(channel_identifier)
      return known_channels[channel_identifier]
    end

    # For now, if it's a handle but not in our known list,
    # we'll treat it as a channel ID for testing purposes
    # In the future, this could use YouTube Search API or handle resolution
    if channel_identifier.start_with?("@")
      # Extract the handle part and try to resolve it
      # For this implementation, we'll raise an error for unknown handles
      raise ArgumentError, "Unknown channel handle: #{channel_identifier}. Please provide a valid channel ID starting with 'UC' or update the known_channels mapping."
    end

    # Assume it's a channel ID if it doesn't start with @
    channel_identifier
  end
end
