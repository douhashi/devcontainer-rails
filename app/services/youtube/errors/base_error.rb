module Youtube
  module Errors
    class BaseError < StandardError
      attr_reader :response_code, :response_body

      def initialize(message = nil, response_code = nil, response_body = nil)
        super(message)
        @response_code = response_code
        @response_body = response_body
      end
    end
  end
end
