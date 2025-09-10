module Youtube
  module Errors
    class NotFoundError < BaseError
      def initialize(message = "YouTube resource not found", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
