module Youtube
  module Errors
    class ApiError < BaseError
      def initialize(message = "YouTube API error", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
