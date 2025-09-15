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
  BORDER_RECT_X = 128
  BORDER_RECT_Y = 72
  BORDER_RECT_WIDTH = 1024
  BORDER_RECT_HEIGHT = 576

  def initialize
    # Ensure required gems are available
    begin
      require "vips"
      Rails.logger.info "Vips library loaded successfully: #{Vips::VERSION}"
    rescue LoadError => e
      Rails.logger.error "Failed to load vips gem: #{e.message}"
      Rails.logger.error "Vips library search paths: #{$LOAD_PATH.grep(/vips/)}"
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
      Rails.logger.error "Input file not found: #{input_path}"
      raise GenerationError, "入力ファイルが見つかりません"
    end

    if File.size(input_path) == 0
      Rails.logger.error "Input file is empty: #{input_path}"
      raise GenerationError, "入力ファイルが空です"
    end

    file_size_mb = File.size(input_path) / (1024.0 * 1024.0)
    if File.size(input_path) > MAX_FILE_SIZE
      Rails.logger.error "File size too large: #{file_size_mb.round(2)}MB (max: #{MAX_FILE_SIZE / (1024 * 1024)}MB)"
      raise GenerationError, "ファイルサイズが大きすぎます: #{file_size_mb.round(2)}MB (最大: #{MAX_FILE_SIZE / (1024 * 1024)}MB)"
    end

    input_ext = File.extname(input_path).downcase
    unless SUPPORTED_IMAGE_FORMATS.include?(input_ext)
      Rails.logger.error "Invalid image format: #{input_ext}. Supported formats: #{SUPPORTED_IMAGE_FORMATS.join(', ')}"
      raise GenerationError, "サポートされていない画像形式です: #{input_ext}"
    end

    # Check if file is actually an image
    begin
      Vips::Image.new_from_file(input_path, access: :sequential)
    rescue Vips::Error => e
      Rails.logger.error "File is not a valid image: #{e.message}"
      raise GenerationError, "有効な画像ファイルではありません"
    end

    Rails.logger.info "Input file validated: #{input_path} (#{File.size(input_path)} bytes)"
  end

  def validate_image_dimensions!(image)
    unless image.width == EXPECTED_INPUT_WIDTH && image.height == EXPECTED_INPUT_HEIGHT
      Rails.logger.warn "Image dimensions #{image.width}x#{image.height} do not match expected #{EXPECTED_INPUT_WIDTH}x#{EXPECTED_INPUT_HEIGHT}"
      raise GenerationError, "画像サイズが不正です: #{image.width}x#{image.height}px (必須: #{EXPECTED_INPUT_WIDTH}x#{EXPECTED_INPUT_HEIGHT}px)"
    end
    Rails.logger.debug "Image dimensions validated: #{image.width}x#{image.height}"
  end

  def resize_to_thumbnail_size(image)
    # Resize from 1920x1080 to 1280x720 (maintaining aspect ratio)
    scale_factor = TARGET_WIDTH.to_f / image.width
    image.resize(scale_factor)
  end

  def draw_white_borders(image)
    # Create a rectangular frame at (128, 72) with size 1024x576 and 10px border width
    # This creates a frame by drawing 4 separate rectangles for each side

    result = image.copy
    white_color = [ 255, 255, 255 ]  # RGB white

    # Calculate frame positions
    frame_left = BORDER_RECT_X
    frame_top = BORDER_RECT_Y
    frame_right = BORDER_RECT_X + BORDER_RECT_WIDTH
    frame_bottom = BORDER_RECT_Y + BORDER_RECT_HEIGHT

    # Draw top border (horizontal)
    result = result.draw_rect(
      white_color,
      frame_left,
      frame_top,
      BORDER_RECT_WIDTH,
      BORDER_WIDTH,
      fill: true
    )

    # Draw bottom border (horizontal)
    result = result.draw_rect(
      white_color,
      frame_left,
      frame_bottom - BORDER_WIDTH,
      BORDER_RECT_WIDTH,
      BORDER_WIDTH,
      fill: true
    )

    # Draw left border (vertical)
    result = result.draw_rect(
      white_color,
      frame_left,
      frame_top,
      BORDER_WIDTH,
      BORDER_RECT_HEIGHT,
      fill: true
    )

    # Draw right border (vertical)
    result = result.draw_rect(
      white_color,
      frame_right - BORDER_WIDTH,
      frame_top,
      BORDER_WIDTH,
      BORDER_RECT_HEIGHT,
      fill: true
    )

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
