module Kie
  module Errors
    class NetworkError < ApiError
      def initialize(message = "Network error occurred", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
