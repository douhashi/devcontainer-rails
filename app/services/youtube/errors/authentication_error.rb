module Youtube
  module Errors
    class AuthenticationError < BaseError
      def initialize(message = "YouTube authentication failed", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
