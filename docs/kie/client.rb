# frozen_string_literal: true

require "httparty"
require "json"
require "net/http"
require "uri"
require "kie/errors"

module Kie
  class Client
    include HTTParty

    BASE_URL = "https://api.kie.ai"
    DEFAULT_TIMEOUT = 30
    DEFAULT_CALLBACK_URL = "https://lofi-bgm-not-exist-server.com/callback"

    def initialize(api_key: nil, base_url: nil)
      @api_key = api_key || ENV.fetch("KIE_AI_API_KEY", nil)
      @base_url = base_url || BASE_URL

      if @api_key.nil? || @api_key.empty?
        raise ConfigurationError,
              "API key is required. Set KIE_AI_API_KEY environment variable or pass api_key parameter"
      end

      self.class.base_uri @base_url
      self.class.default_timeout DEFAULT_TIMEOUT
    end

    def generate_music(prompt:, model: "v3.5", style: nil, wait_audio: false, **options)
      # Apply default callBackUrl if not provided
      options[:callBackUrl] = DEFAULT_CALLBACK_URL unless options.key?(:callBackUrl)

      body = {
        prompt: prompt,
        model: model,
        style: style,
        wait_audio: wait_audio
      }.merge(options).compact

      response = make_request(
        :post,
        "/api/v1/generate",
        body: body.to_json
      )

      response.dig("data", "taskId") || response.dig("data", "task_id")
    end

    def get_task_status(task_id)
      response = make_request(
        :get,
        "/api/v1/generate/record-info",
        query: { taskId: task_id }
      )

      # Return the data portion directly, but preserve the full structure for debugging
      response["data"]
    end

    def extract_audio_urls(task_result)
      return [] unless task_result && task_result["response"]

      tracks = task_result.dig("response", "sunoData") || []
      tracks.select { |track| track["audioUrl"] }
    end

    def download_audio_file(url, output_path)
      uri = URI(url)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)

        if response.code == "200"
          File.binwrite(output_path, response.body)
          return true
        end
      end

      false
    rescue StandardError
      false
    end

    private

    def make_request(method, path, options = {})
      options[:headers] = default_headers.merge(options[:headers] || {})

      begin
        response = self.class.public_send(method, path, options)
        handle_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
        raise NetworkError, "Network error: #{e.message}"
      rescue HTTParty::Error => e
        raise NetworkError, "HTTP error: #{e.message}"
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
            raise AuthenticationError.new(
              "Authentication failed: #{parsed_response['message'] || parsed_response['msg']}",
              code: parsed_response["code"],
              response: parsed_response
            )
          when 429
            raise RateLimitError.new(
              "Rate limit exceeded: #{parsed_response['message'] || parsed_response['msg']}",
              code: parsed_response["code"],
              response: parsed_response
            )
          else
            raise APIError.new(
              "API error: #{parsed_response['message'] || parsed_response['msg']}",
              code: parsed_response["code"],
              response: parsed_response
            )
          end
        end

        parsed_response
      when 401
        raise AuthenticationError.new(
          "Authentication failed. Check your API key",
          code: response.code,
          response: parse_response(response)
        )
      when 429
        raise RateLimitError.new(
          "Rate limit exceeded. Please wait before making more requests",
          code: response.code,
          response: parse_response(response)
        )
      when 400..499
        error_message = parse_error_message(response)
        raise APIError.new(
          "Client error: #{error_message}",
          code: response.code,
          response: parse_response(response)
        )
      when 500..599
        error_message = parse_error_message(response)
        raise APIError.new(
          "Server error: #{error_message}",
          code: response.code,
          response: parse_response(response)
        )
      else
        raise APIError.new(
          "Unexpected response code: #{response.code}",
          code: response.code,
          response: parse_response(response)
        )
      end
    end

    def parse_response(response)
      return {} if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise APIError, "Invalid JSON response: #{e.message}"
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
  end
end
