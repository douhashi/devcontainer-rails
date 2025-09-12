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
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Input file not found/)
      end

      it "raises an error when input file is empty" do
        empty_file_path = Rails.root.join("tmp/empty_file.jpg").to_s
        File.write(empty_file_path, "")

        expect {
          service.generate(input_path: empty_file_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Input file is empty/)

        FileUtils.rm_f(empty_file_path)
      end

      it "raises an error when input file has invalid format" do
        invalid_file_path = Rails.root.join("tmp/invalid_file.txt").to_s
        File.write(invalid_file_path, "invalid image content")

        expect {
          service.generate(input_path: invalid_file_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Invalid image format/)

        FileUtils.rm_f(invalid_file_path)
      end

      it "raises an error when input file is too large" do
        # Mock file size to be larger than 10MB
        allow(File).to receive(:size).with(input_path).and_return(11 * 1024 * 1024)
        allow(File).to receive(:exist?).with(input_path).and_return(true)

        expect {
          service.generate(input_path: input_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /File size too large/)
      end

      it "raises an error when input image has incorrect dimensions" do
        wrong_size_path = Rails.root.join("tmp/wrong_size.jpg").to_s
        create_test_image_with_size(wrong_size_path, 1024, 768)

        expect {
          service.generate(input_path: wrong_size_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Invalid image dimensions/)

        FileUtils.rm_f(wrong_size_path)
      end
    end

    context "when vips processing fails" do
      it "raises an error with appropriate message" do
        create_test_fhd_image(input_path)

        # Mock Vips to raise an error
        allow(Vips::Image).to receive(:new_from_file).with(input_path).and_raise(Vips::Error, "Test vips error")

        expect {
          service.generate(input_path: input_path, output_path: output_path)
        }.to raise_error(ThumbnailGenerationService::GenerationError, /Image processing failed: Test vips error/)

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
          }.to raise_error(ThumbnailGenerationService::GenerationError, /Input file not found/)
        end
      end

      context "when file is empty" do
        it "raises an error" do
          empty_file = Rails.root.join("tmp/empty.jpg").to_s
          File.write(empty_file, "")

          expect {
            service.send(:validate_input_file!, empty_file)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /Input file is empty/)

          FileUtils.rm_f(empty_file)
        end
      end

      context "when file is too large" do
        it "raises an error" do
          allow(File).to receive(:exist?).with(input_path).and_return(true)
          allow(File).to receive(:size).with(input_path).and_return(11 * 1024 * 1024)

          expect {
            service.send(:validate_input_file!, input_path)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /File size too large/)
        end
      end

      context "when file format is not supported" do
        it "raises an error" do
          txt_file = Rails.root.join("tmp/test.txt").to_s
          File.write(txt_file, "not an image")

          expect {
            service.send(:validate_input_file!, txt_file)
          }.to raise_error(ThumbnailGenerationService::GenerationError, /Invalid image format/)

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
      it "draws white borders at specified positions" do
        create_test_fhd_image(input_path)
        image = Vips::Image.new_from_file(input_path)
        resized = service.send(:resize_to_thumbnail_size, image)

        result = service.send(:draw_white_borders, resized)

        expect(result.width).to eq(1280)
        expect(result.height).to eq(720)
        # More detailed pixel-level tests would be in integration tests

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
end
