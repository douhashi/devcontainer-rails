#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to verify vips installation and functionality
require "bundler/setup"
require "image_processing/vips"

puts "=" * 50
puts "Vips Installation Check"
puts "=" * 50

# Check if Vips is available
begin
  puts "\n✓ Vips module loaded successfully"
  puts "  Vips version: #{Vips::VERSION}"
  puts "  Vips library version: #{Vips.version(0)}.#{Vips.version(1)}.#{Vips.version(2)}"
rescue => e
  puts "\n✗ Failed to load Vips: #{e.message}"
  exit 1
end

# Check ImageProcessing availability
begin
  require "image_processing"
  puts "\n✓ ImageProcessing gem loaded successfully"
  puts "  ImageProcessing version: #{ImageProcessing::VERSION}"
rescue => e
  puts "\n✗ Failed to load ImageProcessing: #{e.message}"
  exit 1
end

# Test basic functionality
begin
  puts "\n✓ Creating test image..."
  # Create a simple test image (100x100 blue square)
  test_image = Vips::Image.black(100, 100) + [ 0, 0, 255 ]

  # Save to temporary file
  temp_path = "/tmp/vips_test_#{Time.now.to_i}.jpg"
  test_image.write_to_file(temp_path)
  puts "  Test image created at: #{temp_path}"

  # Test resizing
  puts "\n✓ Testing image resizing..."
  resized = ImageProcessing::Vips
    .source(temp_path)
    .resize_to_limit(50, 50)
    .call

  resized_image = Vips::Image.new_from_file(resized.path)
  puts "  Original: 100x100"
  puts "  Resized: #{resized_image.width}x#{resized_image.height}"

  # Clean up
  File.delete(temp_path) if File.exist?(temp_path)
  File.delete(resized.path) if File.exist?(resized.path)

  puts "\n✓ All checks passed!"
  puts "\nVips is properly installed and functional."
rescue => e
  puts "\n✗ Functionality test failed: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end

puts "\n" + "=" * 50
