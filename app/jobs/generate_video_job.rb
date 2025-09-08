class GenerateVideoJob < ApplicationJob
  queue_as :default

  # SolidQueue concurrency control
  limits_concurrency to: -> { ENV.fetch("VIDEO_GENERATION_CONCURRENCY", "1").to_i },
                     key: -> { "video_generation" }

  # Helper methods for testing
  def self.concurrency_key
    "video_generation"
  end

  def self.concurrency_limit
    ENV.fetch("VIDEO_GENERATION_CONCURRENCY", "1").to_i
  end

  def perform(video_id)
    @video = Video.find(video_id)

    return if @video.status.completed? || @video.status.failed?

    if @video.status.pending?
      start_generation
    elsif @video.status.processing?
      check_generation_status
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def start_generation
    Rails.logger.info "Starting video generation for Video ##{@video.id}"

    begin
      # Validate prerequisites
      validate_prerequisites

      # Update video status
      @video.update!(status: :processing)

      # Get audio and artwork file paths
      audio_path = download_audio_file
      artwork_path = download_artwork_file

      # Generate video using ffmpeg
      output_path = generate_output_path
      generate_video_with_ffmpeg(artwork_path, audio_path, output_path)

      # Attach the generated video file
      attach_video_file(output_path)

      # Analyze and store metadata
      analyze_video_metadata(output_path)

      # Mark as completed
      complete_generation

    ensure
      # Clean up temporary files
      cleanup_temp_files([ audio_path, artwork_path, output_path ])
    end
  end

  def check_generation_status
    Rails.logger.info "Video ##{@video.id} is already processing"
  end

  def validate_prerequisites
    content = @video.content

    unless content.audio&.completed?
      raise StandardError, "Audio must be completed before generating video"
    end

    unless content.artwork.present?
      raise StandardError, "Artwork must be set before generating video"
    end
  end

  def download_audio_file
    audio = @video.content.audio
    temp_path = Rails.root.join("tmp", "video_audio_#{@video.id}_#{Time.current.to_i}.mp3")

    File.open(temp_path, "wb") do |file|
      audio.audio.download do |chunk|
        file.write(chunk)
      end
    end

    temp_path.to_s
  end

  def download_artwork_file
    artwork = @video.content.artwork
    temp_path = Rails.root.join("tmp", "video_artwork_#{@video.id}_#{Time.current.to_i}.jpg")

    File.open(temp_path, "wb") do |file|
      artwork.image.download do |chunk|
        file.write(chunk)
      end
    end

    temp_path.to_s
  end

  def generate_video_with_ffmpeg(artwork_path, audio_path, output_path)
    Rails.logger.info "Generating video with ffmpeg for Video ##{@video.id}"

    # YouTube optimized settings:
    # - H.264 codec with slow preset for quality
    # - 1920x1080 resolution
    # - 30fps frame rate
    # - CRF 18 for high quality
    # - AAC audio codec at 192kbps, 48kHz
    ffmpeg_command = [
      "ffmpeg",
      "-loop", "1",
      "-i", artwork_path,
      "-i", audio_path,
      "-c:v", "libx264",
      "-preset", "slow",
      "-crf", "18",
      "-r", "30",
      "-s", "1920x1080",
      "-c:a", "aac",
      "-b:a", "192k",
      "-ar", "48000",
      "-shortest",
      "-y", # Overwrite output file if exists
      output_path
    ]

    Rails.logger.info "Running ffmpeg command: #{ffmpeg_command.join(' ')}"

    result = system(*ffmpeg_command)

    unless result
      raise StandardError, "ffmpeg command failed with exit status: #{$?.exitstatus}"
    end

    unless File.exist?(output_path)
      raise StandardError, "Output video file was not created"
    end

    Rails.logger.info "Successfully generated video file: #{output_path}"
  end

  def attach_video_file(file_path)
    File.open(file_path, "rb") do |file|
      @video.video = file
    end

    @video.save!

    Rails.logger.info "Successfully attached video file for Video ##{@video.id}"
  end

  def analyze_video_metadata(video_path)
    begin
      # Get file size
      file_size = File.size(video_path)
      @video.file_size = file_size

      # Set standard YouTube optimized settings
      @video.resolution = "1920x1080"

      # Calculate duration from audio file
      if @video.content.audio&.metadata&.dig("duration")
        @video.duration_seconds = @video.content.audio.metadata["duration"].to_i
      end

      @video.save!

      Rails.logger.info "Analyzed metadata for Video ##{@video.id}: size=#{file_size}, resolution=1920x1080"
    rescue StandardError => e
      Rails.logger.error "Failed to analyze video metadata for Video ##{@video.id}: #{e.message}"
      # Continue without metadata - not a critical failure
    end
  end

  def complete_generation
    @video.update!(status: :completed)
    Rails.logger.info "Successfully completed video generation for Video ##{@video.id}"
  end

  def generate_output_path
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    Rails.root.join("tmp", "video_#{@video.id}_#{timestamp}.mp4").to_s
  end

  def cleanup_temp_files(file_paths)
    file_paths.compact.each do |path|
      if path && File.exist?(path)
        File.unlink(path)
        Rails.logger.debug "Cleaned up temporary file: #{path}"
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error cleaning up temporary files: #{e.message}"
  end

  def handle_error(error)
    if @video
      Rails.logger.error "Error in GenerateVideoJob for Video ##{@video.id}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")

      @video.update!(
        status: :failed,
        error_message: "Job error: #{error.message}"
      )
    else
      Rails.logger.error "Error in GenerateVideoJob: #{error.message}"
      raise error
    end
  end
end
