require "open3"
require "timeout"

class AudioAnalysisService
  DEFAULT_DURATION = 180 # 3 minutes as fallback
  FFPROBE_TIMEOUT = 5 # seconds

  def initialize
    # Ensure ffprobe is available
    unless system("which ffprobe > /dev/null 2>&1")
      Rails.logger.warn "ffprobe is not installed or not in PATH"
    end
  end

  def analyze_duration(audio_file_path)
    output = execute_ffprobe(audio_file_path)
    duration_float = Float(output.strip)
    duration_float.to_i
  rescue StandardError => e
    Rails.logger.error "Failed to analyze audio duration for #{audio_file_path}: #{e.message}"
    DEFAULT_DURATION
  end

  private

  def execute_ffprobe(audio_file_path)
    command = [
      "ffprobe",
      "-v", "quiet",
      "-show_entries", "format=duration",
      "-of", "csv=p=0",
      audio_file_path.to_s
    ]

    stdout, stderr, status = Open3.capture3(*command, timeout: FFPROBE_TIMEOUT)

    unless status.success?
      raise StandardError, "ffprobe command failed: #{stderr}"
    end

    stdout
  rescue Timeout::Error
    raise StandardError, "ffprobe command timed out"
  end
end
