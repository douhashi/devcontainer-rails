module Kie
  module Errors
    class InsufficientCreditsError < ApiError
      def initialize(message = "Insufficient credits", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
