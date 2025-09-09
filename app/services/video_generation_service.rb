class VideoGenerationService
  class GenerationError < StandardError; end

  SUPPORTED_AUDIO_FORMATS = %w[.mp3 .m4a .aac .wav .flac .ogg].freeze
  SUPPORTED_IMAGE_FORMATS = %w[.jpg .jpeg .png .bmp .tiff].freeze

  def initialize(video)
    @video = video
  end

  def generate(audio_path:, artwork_path:, output_path:, &progress_block)
    validate_input_files!(audio_path, artwork_path)

    transcoding_options = build_transcoding_options
    encoding_options = build_encoding_options(artwork_path)

    Rails.logger.info "Starting video generation for Video ##{@video.id}"
    Rails.logger.info "Audio: #{audio_path}"
    Rails.logger.info "Artwork: #{artwork_path}"
    Rails.logger.info "Output: #{output_path}"

    audio = FFMPEG::Movie.new(audio_path)
    audio.transcode(output_path, transcoding_options, encoding_options) do |progress|
      Rails.logger.info "Video generation progress: #{(progress * 100).round(2)}%"
      progress_block&.call(progress)
    end

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

    audio_ext = File.extname(audio_path).downcase
    unless SUPPORTED_AUDIO_FORMATS.include?(audio_ext)
      raise GenerationError, "Invalid audio format: #{audio_ext}. Supported formats: #{SUPPORTED_AUDIO_FORMATS.join(', ')}"
    end

    artwork_ext = File.extname(artwork_path).downcase
    unless SUPPORTED_IMAGE_FORMATS.include?(artwork_ext)
      raise GenerationError, "Invalid artwork format: #{artwork_ext}. Supported formats: #{SUPPORTED_IMAGE_FORMATS.join(', ')}"
    end
  end

  def build_transcoding_options
    {
      video_codec: "libx264",
      audio_codec: "aac",
      resolution: "1920x1080",
      video_bitrate: "5000k",
      audio_bitrate: "192k",
      audio_sample_rate: 48000,
      custom: %w[-loop 1 -framerate 30 -preset slow -crf 18 -shortest -pix_fmt yuv420p]
    }
  end

  def build_encoding_options(artwork_path)
    {
      input_options: [ "-loop", "1", "-i", artwork_path ]
    }
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
