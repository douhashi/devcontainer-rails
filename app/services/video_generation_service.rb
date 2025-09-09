class VideoGenerationService
  class GenerationError < StandardError; end

  SUPPORTED_AUDIO_FORMATS = %w[.mp3 .m4a .aac .wav .flac .ogg].freeze
  SUPPORTED_IMAGE_FORMATS = %w[.jpg .jpeg .png .bmp .tiff].freeze

  def initialize(video)
    @video = video
  end

  def generate(audio_path:, artwork_path:, output_path:, &progress_block)
    validate_input_files!(audio_path, artwork_path)

    Rails.logger.info "Starting video generation for Video ##{@video.id}"
    Rails.logger.info "Audio: #{audio_path}"
    Rails.logger.info "Artwork: #{artwork_path}"
    Rails.logger.info "Output: #{output_path}"

    generate_video_with_ffmpeg(audio_path, artwork_path, output_path, &progress_block)

    validate_output!(output_path)
    extract_metadata(output_path)
  rescue FFMPEG::Error => e
    Rails.logger.error "FFmpeg error during video generation: #{e.message}"
    raise GenerationError, "FFmpeg error: #{e.message}"
  rescue => e
    Rails.logger.error "Unexpected error during video generation: #{e.message}"
    raise GenerationError, "Video generation failed: #{e.message}"
  end

  private

  def validate_input_files!(audio_path, artwork_path)
    unless File.exist?(audio_path)
      raise GenerationError, "Audio file not found: #{audio_path}"
    end

    unless File.exist?(artwork_path)
      raise GenerationError, "Artwork file not found: #{artwork_path}"
    end

    # Additional size validation
    if File.size(audio_path) == 0
      raise GenerationError, "Audio file is empty: #{audio_path}"
    end

    if File.size(artwork_path) == 0
      raise GenerationError, "Artwork file is empty: #{artwork_path}"
    end

    audio_ext = File.extname(audio_path).downcase
    unless SUPPORTED_AUDIO_FORMATS.include?(audio_ext)
      raise GenerationError, "Invalid audio format: #{audio_ext}. Supported formats: #{SUPPORTED_AUDIO_FORMATS.join(', ')}"
    end

    artwork_ext = File.extname(artwork_path).downcase
    unless SUPPORTED_IMAGE_FORMATS.include?(artwork_ext)
      raise GenerationError, "Invalid artwork format: #{artwork_ext}. Supported formats: #{SUPPORTED_IMAGE_FORMATS.join(', ')}"
    end

    # Log file information for debugging
    Rails.logger.debug "Input files validated - Audio: #{audio_path} (#{File.size(audio_path)} bytes), Artwork: #{artwork_path} (#{File.size(artwork_path)} bytes)"
  end

  def generate_video_with_ffmpeg(audio_path, artwork_path, output_path, &progress_block)
    # Use system command approach for static image to video conversion
    # as streamio-ffmpeg is primarily designed for video-to-video transcoding

    command = build_ffmpeg_command(audio_path, artwork_path, output_path)
    Rails.logger.info "Executing FFmpeg command: #{command.join(' ')}"

    require "open3"
    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      Rails.logger.error "FFmpeg stderr: #{stderr}"
      Rails.logger.error "FFmpeg stdout: #{stdout}"
      raise FFMPEG::Error, "FFmpeg command failed: #{stderr}"
    end

    Rails.logger.info "Video generation completed successfully"
    progress_block&.call(1.0) if progress_block
  end

  def build_ffmpeg_command(audio_path, artwork_path, output_path)
    # Check if input is already MP3, if so, copy it without re-encoding
    audio_codec_args = if File.extname(audio_path).downcase == ".mp3"
      [ "-c:a", "copy" ]  # Copy MP3 audio without re-encoding
    else
      [ "-c:a", "aac", "-b:a", "192k" ]  # Convert to AAC for other formats
    end

    [
      "ffmpeg",
      "-loop", "1",       # Loop the image
      "-framerate", "1",  # Static image framerate
      "-i", artwork_path,
      "-i", audio_path,
      "-c:v", "libx264",
      "-preset", "slow",
      "-crf", "18",
      *audio_codec_args,    # Audio codec settings (copy or encode)
      "-r", "30",         # Output framerate
      "-shortest",         # Stop when the shortest input ends (audio)
      "-pix_fmt", "yuv420p",
      "-movflags", "+faststart",  # Optimize for web streaming
      "-y",                # Overwrite output file
      output_path
    ]
  end

  def validate_output!(output_path)
    unless File.exist?(output_path)
      raise GenerationError, "Output file was not created: #{output_path}"
    end

    if File.size(output_path) == 0
      raise GenerationError, "Output file is empty: #{output_path}"
    end

    Rails.logger.info "Video generated successfully: #{output_path} (#{File.size(output_path)} bytes)"
  end

  def extract_metadata(output_path)
    movie = FFMPEG::Movie.new(output_path)
    {
      duration: movie.duration,
      resolution: movie.resolution,
      file_size: File.size(output_path)
    }
  rescue => e
    Rails.logger.warn "Failed to extract metadata from video: #{e.message}"
    {
      duration: nil,
      resolution: nil,
      file_size: File.size(output_path)
    }
  end
end
