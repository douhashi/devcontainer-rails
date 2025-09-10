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

  private

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
end
