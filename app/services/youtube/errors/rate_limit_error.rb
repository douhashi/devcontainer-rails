module Youtube
  module Errors
    class RateLimitError < BaseError
      def initialize(message = "YouTube API rate limit exceeded", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
