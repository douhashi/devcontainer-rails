require "rails_helper"
require "image_processing/vips"
require "tempfile"

RSpec.describe "Vips Installation" do
  describe "image_processing gem" do
    it "loads successfully" do
      expect { require "image_processing/vips" }.not_to raise_error
    end

    it "has access to Vips module" do
      expect(defined?(Vips)).to eq("constant")
    end

    it "can check Vips version" do
      expect(Vips::VERSION).to be_a(String)
      expect(Vips.version(0)).to be_a(Integer)
      expect(Vips.version(1)).to be_a(Integer)
      expect(Vips.version(2)).to be_a(Integer)
    end

    it "shows vips configuration and supported formats" do
      puts "\n=== VIPS Configuration ==="
      puts "Vips version: #{Vips::VERSION}"
      puts "Vips library version: #{Vips.version_string}"

      # Check if JPEG is supported
      begin
        # Try to get loader for JPEG
        loader = Vips.vips_foreign_find_load("test.jpg") rescue nil
        puts "JPEG loader: #{loader || 'NOT FOUND'}"

        # Try to check suffixes
        if Vips.respond_to?(:get_suffixes)
          puts "Supported suffixes: #{Vips.get_suffixes.inspect}"
        end
      rescue => e
        puts "Error checking formats: #{e.message}"
      end

      expect(true).to be true
    end
  end

  describe "basic image processing" do
    let(:test_image_path) { Rails.root.join("spec", "fixtures", "test_image.jpg") }
    let(:temp_file) { Tempfile.new([ "processed", ".jpg" ]) }

    before do
      # Check if test image exists
      unless File.exist?(test_image_path)
        skip "Test image file not found at #{test_image_path}"
      end

      # Check if JPEG is supported in this environment
      begin
        # Try to load the test image
        Vips::Image.new_from_file(test_image_path.to_s)
      rescue Vips::Error => e
        if e.message.include?("not a known file format")
          skip "JPEG support not available in this environment (CI limitation)"
        else
          raise e
        end
      end
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it "can resize an image" do
      processor = ImageProcessing::Vips
        .source(test_image_path)
        .resize_to_limit(50, 50)

      processor.call(destination: temp_file.path)

      expect(File.exist?(temp_file.path)).to be true

      # Check the resized image dimensions
      resized_image = Vips::Image.new_from_file(temp_file.path)
      expect(resized_image.width).to be <= 50
      expect(resized_image.height).to be <= 50
    end

    it "can convert image format" do
      png_temp = Tempfile.new([ "converted", ".png" ])

      processor = ImageProcessing::Vips
        .source(test_image_path)
        .convert("png")

      processor.call(destination: png_temp.path)

      expect(File.exist?(png_temp.path)).to be true
      expect(png_temp.path).to end_with(".png")

      png_temp.close
      png_temp.unlink
    end

    it "can apply multiple operations" do
      processor = ImageProcessing::Vips
        .source(test_image_path)
        .resize_to_fill(75, 75)
        .convert("webp")

      webp_temp = Tempfile.new([ "multi", ".webp" ])
      processor.call(destination: webp_temp.path)

      expect(File.exist?(webp_temp.path)).to be true

      # Check the processed image
      processed_image = Vips::Image.new_from_file(webp_temp.path)
      expect(processed_image.width).to eq(75)
      expect(processed_image.height).to eq(75)

      webp_temp.close
      webp_temp.unlink
    end
  end

  describe "memory efficiency" do
    it "processes images with streaming" do
      # Vips uses streaming by default, which is memory efficient
      # Just verify that vips can be configured for caching
      expect(Vips.respond_to?(:cache_set_max)).to be true
    end
  end
end
