module Kie
  module Errors
    class RateLimitError < ApiError
      def initialize(message = "Rate limit exceeded", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
