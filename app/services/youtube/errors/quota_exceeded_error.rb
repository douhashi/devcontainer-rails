module Youtube
  module Errors
    class QuotaExceededError < BaseError
      def initialize(message = "YouTube API quota exceeded", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
