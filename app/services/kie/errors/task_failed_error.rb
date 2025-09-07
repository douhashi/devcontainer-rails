module Kie
  module Errors
    class TaskFailedError < ApiError
      def initialize(message = "Task execution failed", response_code = nil, response_body = nil)
        super(message, response_code, response_body)
      end
    end
  end
end
