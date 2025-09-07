# frozen_string_literal: true

require "open3"
require "fileutils"
require "time"
require_relative "errors"

module Kie
  class VideoGenerator
    SUPPORTED_IMAGE_FORMATS = %w[.jpg .jpeg .png].freeze
    SUPPORTED_AUDIO_FORMATS = %w[.mp3].freeze

    def initialize
      check_ffmpeg_availability!
    end

    def generate(image_path:, audio_path:, output_dir:)
      validate_image_file(image_path)
      validate_audio_file(audio_path)

      FileUtils.mkdir_p(output_dir)

      timestamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      output_filename = "content_#{timestamp}.mp4"
      output_path = File.join(output_dir, output_filename)

      execute_ffmpeg_command(image_path, audio_path, output_path)

      output_path
    end

    def generate_ffmpeg_command(image_path:, audio_path:, output_path:)
      [
        "ffmpeg",
        "-loop", "1",
        "-i", image_path,
        "-i", audio_path,
        "-c:v", "libx264",
        "-preset", "slow",
        "-crf", "20",
        "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,format=yuv420p",
        "-r", "30",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        "-movflags", "+faststart",
        "-y",
        output_path
      ]
    end

    private

    def check_ffmpeg_availability!
      _, _, status = Open3.capture3("ffmpeg", "-version")

      raise FFmpegNotFoundError, "FFmpeg is not installed or not available in PATH" unless status.success?
    rescue Errno::ENOENT
      raise FFmpegNotFoundError, "FFmpeg is not installed or not available in PATH"
    end

    def validate_image_file(path)
      raise InvalidImageFormatError, "Image file not found: #{path}" unless File.exist?(path)

      extension = File.extname(path).downcase
      return if SUPPORTED_IMAGE_FORMATS.include?(extension)

      raise InvalidImageFormatError,
            "Unsupported image format: #{extension}. Supported formats: #{SUPPORTED_IMAGE_FORMATS.join(', ')}"
    end

    def validate_audio_file(path)
      raise InvalidAudioFormatError, "Audio file not found: #{path}" unless File.exist?(path)

      extension = File.extname(path).downcase
      return if SUPPORTED_AUDIO_FORMATS.include?(extension)

      raise InvalidAudioFormatError,
            "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_AUDIO_FORMATS.join(', ')}"
    end

    def execute_ffmpeg_command(image_path, audio_path, output_path)
      command = generate_ffmpeg_command(
        image_path: image_path,
        audio_path: audio_path,
        output_path: output_path
      )

      puts "Generating video..."
      puts "Input image: #{image_path}"
      puts "Input audio: #{audio_path}"
      puts "Output: #{output_path}"
      puts ""

      success = false
      error_output = []

      Open3.popen3(*command) do |stdin, stdout, stderr, thread|
        stdin.close
        stdout.close

        while (line = stderr.gets)
          if line.include?("frame=") || line.include?("time=")
            print "\rProgress: #{extract_progress(line)}"
            $stdout.flush
          else
            error_output << line
          end
        end

        stderr.close
        success = thread.value.success?
      end

      puts ""

      unless success
        error_message = error_output.join("\n")
        raise VideoGenerationError, "Failed to generate video. FFmpeg error:\n#{error_message}"
      end

      puts "Video generated successfully: #{output_path}"
    end

    def extract_progress(line)
      if (match = line.match(/time=(\d{2}:\d{2}:\d{2}\.\d{2})/))
        "Processing time: #{match[1]}"
      elsif (match = line.match(/frame=\s*(\d+)/))
        "Frame: #{match[1]}"
      else
        "Processing..."
      end
    end
  end
end
