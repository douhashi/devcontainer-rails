module Kie
  module Errors
    class TimeoutError < ApiError
      def initialize(message = "Request timed out", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
