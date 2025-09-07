# frozen_string_literal: true

module Kie
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class ApiError < Error
    attr_reader :code, :response

    def initialize(message, code: nil, response: nil)
      super(message)
      @code = code
      @response = response
    end
  end

  class AuthenticationError < ApiError; end

  class RateLimitError < ApiError; end

  class NetworkError < Error; end

  class TimeoutError < Error; end

  class TaskFailedError < Error; end

  class AudioConcatenatorError < Error; end

  class FFmpegNotFoundError < AudioConcatenatorError; end

  class FFprobeNotFoundError < AudioConcatenatorError; end

  class InvalidDurationError < AudioConcatenatorError; end

  class InsufficientFilesError < AudioConcatenatorError; end

  class FileProcessingError < AudioConcatenatorError; end

  class VideoGeneratorError < Error; end

  class InvalidImageFormatError < VideoGeneratorError; end

  class InvalidAudioFormatError < VideoGeneratorError; end

  class VideoGenerationError < VideoGeneratorError; end

  class ImageProcessingError < Error; end
end
