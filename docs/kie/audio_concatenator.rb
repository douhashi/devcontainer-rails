# frozen_string_literal: true

require "open3"
require "json"
require "fileutils"
require "tempfile"
require "time"
require_relative "errors"

module Kie
  class AudioConcatenator
    attr_reader :source_dir, :output_dir, :duration_minutes

    TOLERANCE_SECONDS = 300 # 5 minutes tolerance

    def initialize(source_dir:, output_dir:, duration_minutes:)
      @source_dir = source_dir
      @output_dir = output_dir
      @duration_minutes = duration_minutes

      validate_duration!
    end

    def run
      puts "Checking dependencies..."
      check_dependencies

      puts "Finding mp3 files in #{source_dir}..."
      files = find_mp3_files
      raise InsufficientFilesError, "No mp3 files found in #{source_dir}" if files.empty?

      puts "Found #{files.size} mp3 files"

      puts "Selecting files for #{duration_minutes} minutes..."
      selected = select_files(files)
      puts "Selected #{selected.size} files (#{format_duration(calculate_total_duration(selected))})"

      puts "Concatenating files..."
      output_file = concat_files(selected)

      puts "Output file created: #{output_file}"
      output_file
    end

    def check_dependencies
      check_command("ffmpeg", FFmpegNotFoundError)
      check_command("ffprobe", FFprobeNotFoundError)
    end

    def find_mp3_files
      Dir.glob(File.join(source_dir, "*.mp3"))
    end

    def get_duration(file_path)
      stdout, stderr, status = Open3.capture3(
        "ffprobe", "-v", "error", "-show_format", "-of", "json", file_path
      )

      raise FileProcessingError, "Failed to get duration for #{file_path}: #{stderr}" unless status.success?

      data = JSON.parse(stdout)
      duration = data.dig("format", "duration")

      raise FileProcessingError, "No duration found for #{file_path}" unless duration

      duration.to_f
    end

    def select_files(files)
      target_seconds = duration_minutes * 60
      selected = []
      current_duration = 0

      # Shuffle files for random selection
      shuffled = files.shuffle

      shuffled.each do |file|
        file_duration = get_duration(file)
        selected << file
        current_duration += file_duration

        # Check if we've met the target (within tolerance)
        return selected if current_duration.between?(target_seconds, target_seconds + TOLERANCE_SECONDS)

        # If we've exceeded the tolerance, check if we can continue
        next unless current_duration > target_seconds + TOLERANCE_SECONDS

        # Remove the last file if it exceeds tolerance too much
        if selected.size > 1
          selected.pop
          current_duration -= file_duration
        end
        return selected
      end

      # Check if we have enough duration
      if current_duration < target_seconds
        total_available = calculate_total_duration(files)
        raise InsufficientFilesError,
              "Total available duration (#{format_duration(total_available)}) " \
              "is less than requested (#{format_duration(target_seconds)})"
      end

      selected
    end

    def concat_files(files)
      # Create output directory if it doesn't exist
      FileUtils.mkdir_p(output_dir)

      # Generate output filename with timestamp
      timestamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      output_file = File.join(output_dir, "concat_#{timestamp}.mp3")

      # Create temporary file list for concat demuxer
      list_file = Tempfile.new([ "concat_list_", ".txt" ])
      begin
        # Write file paths to list
        files.each do |file|
          list_file.puts("file '#{File.expand_path(file)}'")
        end
        list_file.close

        # Run FFmpeg concat
        # NOTE: Using Open3.capture3 with separate arguments prevents command injection
        # Each argument is passed separately, not as a single shell command string
        _stdout, stderr, status = Open3.capture3(
          "ffmpeg", "-f", "concat", "-safe", "0", "-i", list_file.path,
          "-c", "copy", "-y", output_file
        )

        raise FileProcessingError, "Failed to concatenate files: #{stderr}" unless status.success?

        output_file
      ensure
        list_file&.unlink
      end
    end

    private

    def validate_duration!
      return if duration_minutes.is_a?(Numeric) && duration_minutes.positive?

      raise InvalidDurationError, "Duration must be a positive number"
    end

    def check_command(command, error_class)
      _stdout, _stderr, status = Open3.capture3("which", command)
      raise error_class, "#{command} is not installed or not in PATH" unless status.success?
    end

    def calculate_total_duration(files)
      files.sum { |file| get_duration(file) }
    end

    def format_duration(seconds)
      minutes = (seconds / 60).floor
      remaining_seconds = (seconds % 60).floor
      "#{minutes}m #{remaining_seconds}s"
    end
  end
end
