module Kie
  module Errors
    class AuthenticationError < ApiError
      def initialize(message = "Invalid API key", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
