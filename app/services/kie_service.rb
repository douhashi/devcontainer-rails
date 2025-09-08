class KieService
  include HTTParty

  base_uri "https://api.kie.ai"
  default_timeout 30

  DEFAULT_MODEL = "V4_5PLUS"
  DEFAULT_CALLBACK_URL = "https://lofi-bgm-not-exist-server.com/callback"
  MAX_PROMPT_LENGTH = 3000
  MAX_RETRIES = 3
  RETRY_DELAY = 1 # seconds

  def initialize
    @api_key = ENV.fetch("KIE_AI_API_KEY", nil)

    if @api_key.nil? || @api_key.empty?
      raise Kie::Errors::AuthenticationError, "KIE_AI_API_KEY is not set"
    end
  end

  def generate_music(prompt:, model: DEFAULT_MODEL, style: nil, wait_audio: false, custom_mode: false, instrumental: true, **options)
    validate_prompt(prompt)

    # Apply default callBackUrl if not provided
    options[:callBackUrl] = DEFAULT_CALLBACK_URL unless options.key?(:callBackUrl)

    body = {
      prompt: prompt,
      model: model,
      style: style,
      wait_audio: wait_audio,
      customMode: custom_mode,
      instrumental: instrumental
    }.merge(options).compact

    response = with_retry do
      make_request(
        :post,
        "/api/v1/generate",
        body: body.to_json
      )
    end

    response.dig("data", "taskId") || response.dig("data", "task_id")
  end

  def get_task_status(task_id)
    raise ArgumentError, "Task ID cannot be blank" if task_id.to_s.strip.empty?

    response = with_retry do
      make_request(
        :get,
        "/api/v1/generate/record-info",
        query: { taskId: task_id }
      )
    end

    task_data = response["data"]

    # Log full response in development environment
    if Rails.env.development? && task_data
      Rails.logger.debug "KIE API Response for task #{task_id}: #{JSON.pretty_generate(task_data)}"
    end

    # Validate response format
    validate_task_response(task_data) if task_data

    # Check if task failed
    if task_data && task_data["status"] == "failed"
      error_message = task_data["error"] || "Generation failed"
      raise Kie::Errors::TaskFailedError, error_message
    end

    task_data
  end

  def download_audio(audio_url, file_path)
    raise ArgumentError, "Audio URL cannot be blank" if audio_url.to_s.strip.empty?
    raise ArgumentError, "File path cannot be blank" if file_path.to_s.strip.empty?

    with_retry do
      uri = URI(audio_url)
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        # Ensure directory exists
        FileUtils.mkdir_p(File.dirname(file_path))

        File.binwrite(file_path, response.body)
        file_path
      else
        raise Kie::Errors::NetworkError, "Failed to download audio: HTTP #{response.code}"
      end
    end
  rescue ArgumentError => e
    # Re-raise ArgumentError as is
    raise
  rescue StandardError => e
    raise Kie::Errors::NetworkError, "Download failed: #{e.message}"
  end

  def extract_music_data(task_data)
    return nil unless task_data.is_a?(Hash)

    # Extract sunoData from response structure
    suno_data = task_data.dig("response", "sunoData")
    return nil unless suno_data.is_a?(Array) && !suno_data.empty?

    # Get the first music variant
    first_music = suno_data.first
    return nil unless first_music.is_a?(Hash)

    # Audio URL is required
    audio_url = first_music["audioUrl"]
    return nil if audio_url.nil? || audio_url.to_s.strip.empty?

    # Extract music metadata with extended fields
    {
      audio_url: audio_url,
      title: first_music["title"],
      tags: first_music["tags"],
      duration: first_music["duration"],
      model_name: first_music["modelName"],
      generated_prompt: first_music["prompt"],
      audio_id: first_music["audioId"]
    }
  end

  def extract_all_music_data(task_data)
    return [] unless task_data.is_a?(Hash)

    # Extract sunoData from response structure
    suno_data = task_data.dig("response", "sunoData")
    return [] unless suno_data.is_a?(Array)

    # Extract metadata for all music variants
    suno_data.filter_map do |music|
      next unless music.is_a?(Hash)

      # Audio URL is required
      audio_url = music["audioUrl"]
      next if audio_url.nil? || audio_url.to_s.strip.empty?

      # Extract music metadata with extended fields
      {
        audio_url: audio_url,
        title: music["title"],
        tags: music["tags"],
        duration: music["duration"],
        model_name: music["modelName"],
        generated_prompt: music["prompt"],
        audio_id: music["audioId"]
      }
    end
  end

  private

  attr_reader :api_key

  def make_request(method, path, options = {})
    options[:headers] = default_headers.merge(options[:headers] || {})

    begin
      response = self.class.public_send(method, path, options)
      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise Kie::Errors::NetworkError, "Network error: #{e.message}"
    rescue HTTParty::Error => e
      raise Kie::Errors::NetworkError, "HTTP error: #{e.message}"
    end
  end

  def handle_response(response)
    case response.code
    when 200..299
      parsed_response = parse_response(response)

      # Handle API errors returned with 200 status
      if parsed_response["code"] && parsed_response["code"] != 200 && parsed_response["code"] != 0
        case parsed_response["code"]
        when 401
          raise Kie::Errors::AuthenticationError.new(
            "Authentication failed: #{parsed_response['message'] || parsed_response['msg']}",
            parsed_response["code"],
            parsed_response
          )
        when 429
          raise Kie::Errors::RateLimitError.new(
            "Rate limit exceeded: #{parsed_response['message'] || parsed_response['msg']}",
            parsed_response["code"],
            parsed_response
          )
        else
          raise Kie::Errors::ApiError.new(
            "API error: #{parsed_response['message'] || parsed_response['msg']}",
            parsed_response["code"],
            parsed_response
          )
        end
      end

      parsed_response
    when 401
      raise Kie::Errors::AuthenticationError.new(
        "Authentication failed. Check your API key",
        response.code,
        parse_response(response)
      )
    when 404
      error_message = parse_error_message(response)
      raise Kie::Errors::ApiError.new(
        "Not found: #{error_message}",
        response.code,
        parse_response(response)
      )
    when 429
      raise Kie::Errors::RateLimitError.new(
        "Rate limit exceeded. Please wait before making more requests",
        response.code,
        parse_response(response)
      )
    when 400..499
      error_message = parse_error_message(response)
      raise Kie::Errors::ApiError.new(
        "Client error: #{error_message}",
        response.code,
        parse_response(response)
      )
    when 500..599
      error_message = parse_error_message(response)
      raise Kie::Errors::ApiError.new(
        "Server error: #{error_message}",
        response.code,
        parse_response(response)
      )
    else
      raise Kie::Errors::ApiError.new(
        "Unexpected response code: #{response.code}",
        response.code,
        parse_response(response)
      )
    end
  end

  def parse_response(response)
    return {} if response.body.nil? || response.body.empty?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise Kie::Errors::ApiError, "Invalid JSON response: #{e.message}"
  end

  def parse_error_message(response)
    parsed = parse_response(response)
    parsed["message"] || parsed["error"] || "Unknown error"
  rescue StandardError
    "Unknown error (status: #{response.code})"
  end

  def default_headers
    {
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def validate_prompt(prompt)
    raise ArgumentError, "Prompt cannot be blank" if prompt.to_s.strip.empty?
    raise ArgumentError, "Prompt is too long (maximum #{MAX_PROMPT_LENGTH} characters)" if prompt.length > MAX_PROMPT_LENGTH
  end

  def with_retry(max_retries: MAX_RETRIES, &block)
    retries = 0
    begin
      yield
    rescue Kie::Errors::NetworkError, Kie::Errors::RateLimitError => e
      retries += 1
      if retries < max_retries
        Rails.logger.info "Retrying after error: #{e.message} (attempt #{retries + 1}/#{max_retries})"
        sleep(RETRY_DELAY * retries) # Exponential backoff
        retry
      else
        raise
      end
    end
  end

  def validate_task_response(task_data)
    # Check if response is a Hash
    unless task_data.is_a?(Hash)
      Rails.logger.warn "Unexpected response format for KIE API task status: #{task_data.class} instead of Hash"
      return
    end

    # Check for required fields
    required_fields = %w[taskId status]
    missing_fields = required_fields - task_data.keys

    missing_fields.each do |field|
      Rails.logger.warn "Missing required field: #{field} in KIE API response. Response keys: #{task_data.keys.join(', ')}"
    end

    # Log if status has unexpected value (for monitoring API changes)
    if task_data["status"]
      expected_statuses = %w[pending processing completed failed success]
      normalized_status = task_data["status"].to_s.downcase
      unless expected_statuses.include?(normalized_status)
        Rails.logger.warn "Unexpected status value in KIE API response: '#{task_data['status']}'"
      end
    end
  end
end
