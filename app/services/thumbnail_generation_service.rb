class ThumbnailGenerationService
  class GenerationError < StandardError; end

  SUPPORTED_IMAGE_FORMATS = %w[.jpg .jpeg .png .bmp .tiff].freeze
  MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
  TARGET_WIDTH = 1280
  TARGET_HEIGHT = 720
  EXPECTED_INPUT_WIDTH = 1920
  EXPECTED_INPUT_HEIGHT = 1080
  JPEG_QUALITY = 92
  BORDER_WIDTH = 10
  BORDER_POSITION_TOP = 100
  BORDER_POSITION_BOTTOM = 620  # 720 - 100

  def initialize
    # Ensure required gems are available
    begin
      require "vips"
    rescue LoadError => e
      Rails.logger.error "Failed to load vips gem: #{e.message}"
      raise GenerationError, "Image processing library not available: #{e.message}"
    end
  end

  def generate(input_path:, output_path:)
    validate_input_file!(input_path)

    Rails.logger.info "Starting thumbnail generation from #{input_path} to #{output_path}"

    begin
      # Load and validate input image
      image = Vips::Image.new_from_file(input_path)
      validate_image_dimensions!(image)

      # Process the image through the pipeline
      thumbnail = resize_to_thumbnail_size(image)
      thumbnail = draw_white_borders(thumbnail)
      thumbnail = add_text_overlay(thumbnail)

      # Save the final result
      save_thumbnail(thumbnail, output_path)

      validate_output!(output_path)

      Rails.logger.info "Thumbnail generated successfully: #{output_path} (#{File.size(output_path)} bytes)"

      {
        input_size: { width: image.width, height: image.height },
        output_size: { width: TARGET_WIDTH, height: TARGET_HEIGHT },
        file_size: File.size(output_path)
      }
    rescue Vips::Error => e
      Rails.logger.error "Vips error during thumbnail generation: #{e.message}"
      raise GenerationError, "Image processing failed: #{e.message}"
    rescue => e
      Rails.logger.error "Unexpected error during thumbnail generation: #{e.message}"
      raise GenerationError, "Thumbnail generation failed: #{e.message}"
    end
  end

  private

  def validate_input_file!(input_path)
    unless File.exist?(input_path)
      raise GenerationError, "Input file not found: #{input_path}"
    end

    if File.size(input_path) == 0
      raise GenerationError, "Input file is empty: #{input_path}"
    end

    if File.size(input_path) > MAX_FILE_SIZE
      raise GenerationError, "File size too large: #{File.size(input_path)} bytes (max: #{MAX_FILE_SIZE} bytes)"
    end

    input_ext = File.extname(input_path).downcase
    unless SUPPORTED_IMAGE_FORMATS.include?(input_ext)
      raise GenerationError, "Invalid image format: #{input_ext}. Supported formats: #{SUPPORTED_IMAGE_FORMATS.join(', ')}"
    end

    Rails.logger.debug "Input file validated: #{input_path} (#{File.size(input_path)} bytes)"
  end

  def validate_image_dimensions!(image)
    unless image.width == EXPECTED_INPUT_WIDTH && image.height == EXPECTED_INPUT_HEIGHT
      Rails.logger.warn "Image dimensions #{image.width}x#{image.height} do not match expected #{EXPECTED_INPUT_WIDTH}x#{EXPECTED_INPUT_HEIGHT}"
      raise GenerationError, "Invalid image dimensions: #{image.width}x#{image.height}. Expected: #{EXPECTED_INPUT_WIDTH}x#{EXPECTED_INPUT_HEIGHT}"
    end
    Rails.logger.debug "Image dimensions validated: #{image.width}x#{image.height}"
  end

  def resize_to_thumbnail_size(image)
    # Resize from 1920x1080 to 1280x720 (maintaining aspect ratio)
    scale_factor = TARGET_WIDTH.to_f / image.width
    image.resize(scale_factor)
  end

  def draw_white_borders(image)
    # Create white rectangles at specified positions
    # Top border: y=100, width=1280, height=10
    # Bottom border: y=620, width=1280, height=10

    result = image.copy
    white_color = [ 255, 255, 255 ]  # RGB white

    # Draw top border
    result = result.draw_rect(white_color, 0, BORDER_POSITION_TOP, TARGET_WIDTH, BORDER_WIDTH, fill: true)

    # Draw bottom border
    result = result.draw_rect(white_color, 0, BORDER_POSITION_BOTTOM, TARGET_WIDTH, BORDER_WIDTH, fill: true)

    result
  end

  def add_text_overlay(image)
    # Add "Lofi BGM" text in the center of the image
    text = "Lofi BGM"

    # Text positioning (center of 1280x720 image)
    text_x = TARGET_WIDTH / 2
    text_y = TARGET_HEIGHT / 2

    # Create text with specified styling
    # Use system font with fallbacks
    font_spec = "Noto Sans Bold 48"

    begin
      # Create text image
      text_image = Vips::Image.text(
        text,
        font: font_spec,
        fontfile: find_system_font,
        rgba: true
      )

      # Create a composite with the text centered
      # Calculate position to center the text
      left = text_x - (text_image.width / 2)
      top = text_y - (text_image.height / 2)

      # Composite the text onto the image
      image.composite(text_image, :over, x: left, y: top)
    rescue Vips::Error => e
      Rails.logger.warn "Failed to render text with system font, using basic text rendering: #{e.message}"

      # Fallback to simpler text rendering if font rendering fails
      image.draw_text(text, text_x - 100, text_y - 20, color: [ 255, 255, 255 ])
    end
  end

  def find_system_font
    # Try to find a suitable system font
    possible_fonts = [
      "/System/Library/Fonts/Arial.ttf",                    # macOS
      "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", # Ubuntu/Debian
      "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", # CentOS/RHEL
      "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",  # Common on many systems
      "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf", # Alternative path
      "/Windows/Fonts/arial.ttf"                            # Windows
    ]

    font = possible_fonts.find { |f| File.exist?(f) }
    Rails.logger.debug "Found system font: #{font}" if font
    Rails.logger.warn "No suitable system font found, will use fallback rendering" unless font
    font
  end

  def save_thumbnail(image, output_path)
    begin
      # Ensure output directory exists
      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

      # Save as JPEG with specified quality
      image.write_to_file(output_path, Q: JPEG_QUALITY)
    rescue => e
      Rails.logger.error "Failed to save thumbnail to #{output_path}: #{e.message}"
      raise GenerationError, "Failed to save output file: #{e.message}"
    end
  end

  def validate_output!(output_path)
    unless File.exist?(output_path)
      raise GenerationError, "Output file was not created: #{output_path}"
    end

    if File.size(output_path) == 0
      raise GenerationError, "Output file is empty: #{output_path}"
    end

    # Verify the output file is a valid image with correct dimensions
    begin
      output_image = Vips::Image.new_from_file(output_path)
      unless output_image.width == TARGET_WIDTH && output_image.height == TARGET_HEIGHT
        raise GenerationError, "Output file has incorrect dimensions: #{output_image.width}x#{output_image.height}"
      end
    rescue Vips::Error => e
      raise GenerationError, "Output file is not a valid image: #{e.message}"
    end
  end
end
