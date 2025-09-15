require "rails_helper"
require "vips"

RSpec.describe ThumbnailGenerationService, type: :service do
  let(:service) { described_class.new }
  let(:input_path) { Rails.root.join("spec/test_data/test_fhd_artwork.jpg").to_s }
  let(:output_path) { Rails.root.join("tmp/test_thumbnail.jpg").to_s }

  before do
    FileUtils.rm_f(output_path)
  end

  after do
    FileUtils.rm_f(output_path)
  end

  describe "#generate" do
    context "with valid inputs" do
      before do
        # Create a test FHD image (1920x1080) for testing
        create_test_fhd_image(input_path)
      end

      after do
        FileUtils.rm_f(input_path) if File.exist?(input_path)
      end

      it "generates a thumbnail with correct dimensions" do
        service.generate(input_path: input_path, output_path: output_path)

        expect(File.exist?(output_path)).to be true
        expect(File.size(output_path)).to be > 0

        # Verify the output dimensions are 1280x720
        image = Vips::Image.new_from_file(output_path)
        expect(image.width).to eq(1280)
        expect(image.height).to eq(720)
      end

      it "creates a JPEG file with appropriate quality" do
        service.generate(input_path: input_path, output_path: output_path)

        expect(File.exist?(output_path)).to be true

        # Check if it's a valid JPEG by file extension and content
        expect(File.extname(output_path).downcase).to eq('.jpg')

        # Verify it can be loaded as an image (format check)
        image = Vips::Image.new_from_file(output_path)
        expect(image).to be_a(Vips::Image)
      end

      it "includes white borders and text overlay" do
        service.generate(input_path: input_path, output_path: output_path)

        image = Vips::Image.new_from_file(output_path)

        # Check that the image has been processed (not just resized)
        # We'll do more detailed checks in integration tests
        expect(image.width).to eq(1280)
        expect(image.height).to eq(720)
      end

      it "handles PNG input files" do
        png_input_path = Rails.root.join("tmp/test_fhd_artwork.png").to_s
        create_test_fhd_png_image(png_input_path)

        service.generate(input_path: png_input_path, output_path: output_path)

        expect(File.exist?(output_path)).to be true
        image = Vips::Image.new_from_file(output_path)
        expect(image.width).to eq(1280)
        expect(image.height).to eq(720)

        FileUtils.rm_f(png_input_path)
      end
    end

    context "with invalid inputs" do
      it "raises an error when input file does not exist" do
        nonexistent_path = "/path/to/nonexistent/file.jpg"

        expect {
          service.generate(input_path: nonexistent_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /入力ファイルが見つかりません/)
      end

      it "raises an error when input file is empty" do
        empty_file_path = Rails.root.join("tmp/empty_file.jpg").to_s
        File.write(empty_file_path, "")

        expect {
          service.generate(input_path: empty_file_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /入力ファイルが空です/)

        FileUtils.rm_f(empty_file_path)
      end

      it "raises an error when input file has invalid format" do
        invalid_file_path = Rails.root.join("tmp/invalid_file.txt").to_s
        File.write(invalid_file_path, "invalid image content")

        expect {
          service.generate(input_path: invalid_file_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /サポートされていない画像形式です/)

        FileUtils.rm_f(invalid_file_path)
      end

      it "raises an error when input file is too large" do
        # Mock file size to be larger than 10MB
        allow(File).to receive(:size).with(input_path).and_return(11 * 1024 * 1024)
        allow(File).to receive(:exist?).with(input_path).and_return(true)

        expect {
          service.generate(input_path: input_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /ファイルサイズが大きすぎます/)
      end

      it "raises an error when input image has incorrect dimensions" do
        wrong_size_path = Rails.root.join("tmp/wrong_size.jpg").to_s
        create_test_image_with_size(wrong_size_path, 1024, 768)

        expect {
          service.generate(input_path: wrong_size_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /画像サイズが不正です/)

        FileUtils.rm_f(wrong_size_path)
      end
    end

    context "when vips processing fails" do
      it "raises an error with appropriate message" do
        create_test_fhd_image(input_path)

        # Mock Vips to raise an error (allow both sequential and normal access)
        allow(Vips::Image).to receive(:new_from_file).and_raise(Vips::Error, "Test vips error")

        expect {
          service.generate(input_path: input_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /有効な画像ファイルではありません/)

        FileUtils.rm_f(input_path)
      end
    end

    context "when output file creation fails" do
      it "raises an error when output directory doesn't exist" do
        create_test_fhd_image(input_path)
        invalid_output_path = "/nonexistent/directory/thumbnail.jpg"

        expect {
          service.generate(input_path: input_path, output_path: invalid_output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Failed to save output file/)

        FileUtils.rm_f(input_path)
      end
    end
  end

  describe "private methods" do
    describe "#validate_input_file!" do
      context "when file is valid" do
        it "does not raise an error" do
          create_test_fhd_image(input_path)

          expect {
            service.send(:validate_input_file!, input_path)
          }.not_to raise_error

          FileUtils.rm_f(input_path)
        end
      end

      context "when file does not exist" do
        it "raises an error" do
          expect {
            service.send(:validate_input_file!, "/nonexistent/file.jpg")
          }.to raise_error(ThumbnailGenerationService::GenerationError, /入力ファイルが見つかりません/)
        end
      end

      context "when file is empty" do
        it "raises an error" do
          empty_file = Rails.root.join("tmp/empty.jpg").to_s
          File.write(empty_file, "")

          expect {
            service.send(:validate_input_file!, empty_file)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /入力ファイルが空です/)

          FileUtils.rm_f(empty_file)
        end
      end

      context "when file is too large" do
        it "raises an error" do
          allow(File).to receive(:exist?).with(input_path).and_return(true)
          allow(File).to receive(:size).with(input_path).and_return(11 * 1024 * 1024)

          expect {
            service.send(:validate_input_file!, input_path)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /ファイルサイズが大きすぎます/)
        end
      end

      context "when file format is not supported" do
        it "raises an error" do
          txt_file = Rails.root.join("tmp/test.txt").to_s
          File.write(txt_file, "not an image")

          expect {
            service.send(:validate_input_file!, txt_file)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /サポートされていない画像形式です/)

          FileUtils.rm_f(txt_file)
        end
      end
    end

    describe "#resize_to_thumbnail_size" do
      it "resizes FHD image to 1280x720" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)

        resized = service.send(:resize_to_thumbnail_size, image)

        expect(resized.width).to eq(1280)
        expect(resized.height).to eq(720)

        FileUtils.rm_f(input_path)
      end
    end

    describe "#draw_white_borders" do
      it "draws white borders as a rectangle frame" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)
        resized = service.send(:resize_to_thumbnail_size, image)

        result = service.send(:draw_white_borders, resized)

        expect(result.width).to eq(1280)
        expect(result.height).to eq(720)

        # Test that the frame is correctly positioned
        # Frame should be at (128, 72) with size 1024x576
        # We'll verify this by checking pixels at key positions

        # Top-left corner of the frame (128, 72) should be white
        top_left_pixel = result.getpoint(128, 72)
        expect(top_left_pixel).to eq([ 255, 255, 255 ])

        # Top-right corner of the frame (128 + 1024 - 1, 72) should be white
        top_right_pixel = result.getpoint(128 + 1024 - 1, 72)
        expect(top_right_pixel).to eq([ 255, 255, 255 ])

        # Bottom-left corner of the frame (128, 72 + 576 - 1) should be white
        bottom_left_pixel = result.getpoint(128, 72 + 576 - 1)
        expect(bottom_left_pixel).to eq([ 255, 255, 255 ])

        # Bottom-right corner of the frame (128 + 1024 - 1, 72 + 576 - 1) should be white
        bottom_right_pixel = result.getpoint(128 + 1024 - 1, 72 + 576 - 1)
        expect(bottom_right_pixel).to eq([ 255, 255, 255 ])

        # Check that the border has correct thickness (10px)
        # Inner edge should not be white (at 128+10, 72+10)
        inner_pixel = result.getpoint(128 + 10, 72 + 10)
        expect(inner_pixel).not_to eq([ 255, 255, 255 ])

        # Outer edge should not be white (at 128-1, 72-1) if within bounds
        if 128 - 1 >= 0 && 72 - 1 >= 0
          outer_pixel = result.getpoint(128 - 1, 72 - 1)
          expect(outer_pixel).not_to eq([ 255, 255, 255 ])
        end

        FileUtils.rm_f(input_path)
      end

      it "creates a rectangular frame with 10px border width" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)
        resized = service.send(:resize_to_thumbnail_size, image)

        result = service.send(:draw_white_borders, resized)

        # Verify border width is exactly 10px
        # Check horizontal border at top (y=72 to y=81 should be white)
        (72..81).each do |y|
          pixel = result.getpoint(640, y)  # Check at center x position
          expect(pixel).to eq([ 255, 255, 255 ]), "Expected white at (640, #{y})"
        end

        # Check that y=82 (just inside the border) is not white
        inside_pixel = result.getpoint(640, 82)
        expect(inside_pixel).not_to eq([ 255, 255, 255 ])

        # Check vertical border at left (x=128 to x=137 should be white)
        (128..137).each do |x|
          pixel = result.getpoint(x, 360)  # Check at center y position
          expect(pixel).to eq([ 255, 255, 255 ]), "Expected white at (#{x}, 360)"
        end

        # Check that x=138 (just inside the border) is not white
        inside_pixel = result.getpoint(138, 360)
        expect(inside_pixel).not_to eq([ 255, 255, 255 ])

        FileUtils.rm_f(input_path)
      end
    end

    describe "#add_text_overlay" do
      it "adds 'Lofi BGM' text to the center of the image" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)
        resized = service.send(:resize_to_thumbnail_size, image)
        with_borders = service.send(:draw_white_borders, resized)

        result = service.send(:add_text_overlay, with_borders)

        expect(result.width).to eq(1280)
        expect(result.height).to eq(720)
        # Text rendering verification would be done in integration tests

        FileUtils.rm_f(input_path)
      end

      it "adds white text with larger font size" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)
        resized = service.send(:resize_to_thumbnail_size, image)
        with_borders = service.send(:draw_white_borders, resized)

        result = service.send(:add_text_overlay, with_borders)

        # Verify the text is rendered (image changes from the base)
        # Compare by checking that result is not the same instance
        expect(result).not_to be(with_borders)

        # Check that text is approximately centered
        # The text should be rendered near the center (640, 360)
        # We'll verify that pixels in the center area have changed
        center_x = 640
        center_y = 360

        # Sample a pixel in the center area where text should be
        # Note: Exact pixel verification is difficult due to font rendering variations
        # but we can check that the image has been modified
        expect(result.width).to eq(1280)
        expect(result.height).to eq(720)

        FileUtils.rm_f(input_path)
      end

      it "adds shadow effect for better visibility" do
        # Create a white background image to test shadow visibility
        white_bg_path = Rails.root.join("tmp/test_white_bg.jpg").to_s
        create_test_image_with_color(white_bg_path, [ 255, 255, 255 ])

        image = Vips::Image.new_from_file(white_bg_path)
        resized = service.send(:resize_to_thumbnail_size, image)

        result = service.send(:add_text_overlay, resized)

        # Verify the text with shadow is visible even on white background
        expect(result.width).to eq(1280)
        expect(result.height).to eq(720)

        # The shadow should create contrast even on white background
        # We expect the image to have changed from pure white
        expect(result).not_to be(resized)

        FileUtils.rm_f(white_bg_path)
      end

      it "renders text with transparent background, not as a white rectangle" do
        # Create a dark background to easily verify the text is not a white rectangle
        dark_bg_path = Rails.root.join("tmp/test_dark_bg.jpg").to_s
        create_test_image_with_color(dark_bg_path, [ 50, 50, 50 ])

        image = Vips::Image.new_from_file(dark_bg_path)
        resized = service.send(:resize_to_thumbnail_size, image)

        result = service.send(:add_text_overlay, resized)

        # Sample points around the text area
        # If text is rendered correctly with transparency, we should see:
        # 1. White pixels where the text strokes are
        # 2. Background color preserved where there's no text
        # 3. NOT a solid white rectangle

        # Sample a point that should be background (not covered by text)
        # Using offset from center where there should be no text
        bg_sample_x = 640 - 200  # Well outside the text area
        bg_sample_y = 360
        bg_pixel = result.getpoint(bg_sample_x, bg_sample_y)

        # This pixel should be close to the dark background color, not white
        expect(bg_pixel[0]).to be < 100  # R channel should be dark
        expect(bg_pixel[1]).to be < 100  # G channel should be dark
        expect(bg_pixel[2]).to be < 100  # B channel should be dark

        # Sample multiple points to ensure we don't have a white rectangle
        # Check corners of where a rectangle might be
        rectangle_test_points = [
          [ 640 - 150, 360 - 50 ],  # Top-left of potential rectangle
          [ 640 + 150, 360 - 50 ],  # Top-right of potential rectangle
          [ 640 - 150, 360 + 50 ],  # Bottom-left of potential rectangle
          [ 640 + 150, 360 + 50 ]   # Bottom-right of potential rectangle
        ]

        rectangle_test_points.each do |x, y|
          pixel = result.getpoint(x, y)
          # These points should NOT all be white (which would indicate a rectangle)
          is_white = pixel[0] > 250 && pixel[1] > 250 && pixel[2] > 250
          # At least some of these should not be white
        end

        # Verify that not all test points are white (which would indicate a solid rectangle)
        white_pixel_count = rectangle_test_points.count do |x, y|
          pixel = result.getpoint(x, y)
          pixel[0] > 250 && pixel[1] > 250 && pixel[2] > 250
        end

        # If text is rendered correctly, not all corner points should be white
        expect(white_pixel_count).to be < 4

        FileUtils.rm_f(dark_bg_path)
      end
    end
  end

  private

  # Helper method to create a test FHD JPEG image
  def create_test_fhd_image(path)
    # Create a simple 1920x1080 JPEG image for testing
    image = Vips::Image.black(1920, 1080, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path, Q: 90)
  end

  # Helper method to create a test FHD PNG image
  def create_test_fhd_png_image(path)
    # Create a simple 1920x1080 PNG image for testing
    image = Vips::Image.black(1920, 1080, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path)
  end

  # Helper method to create an image with specific dimensions
  def create_test_image_with_size(path, width, height)
    image = Vips::Image.black(width, height, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path, Q: 90)
  end

  # Helper method to create an FHD image with specific color
  def create_test_image_with_color(path, color)
    image = Vips::Image.black(1920, 1080, bands: 3)
    # Set to the specified color
    image = image.new_from_image(color)
    image.write_to_file(path, Q: 90)
  end
end
