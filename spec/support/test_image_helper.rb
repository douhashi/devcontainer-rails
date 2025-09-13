# frozen_string_literal: true

module TestImageHelper
  # Create a test JPEG image with specified dimensions
  def create_test_image_with_size(path, width, height)
    # Create directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(path))

    # Create a minimal JPEG file without using external libraries
    # This creates a valid JPEG header with specified dimensions
    File.open(path, 'wb') do |f|
      # JPEG SOI marker
      f.write([ 0xFF, 0xD8 ].pack('C*'))

      # APP0 marker
      f.write([ 0xFF, 0xE0 ].pack('C*'))
      f.write([ 0x00, 0x10 ].pack('n'))  # Length
      f.write('JFIF')
      f.write([ 0x00 ].pack('C'))  # null terminator
      f.write([ 0x01, 0x01 ].pack('C*'))  # JFIF version
      f.write([ 0x00 ].pack('C'))  # units
      f.write([ 0x00, 0x01 ].pack('n'))  # X density
      f.write([ 0x00, 0x01 ].pack('n'))  # Y density
      f.write([ 0x00, 0x00 ].pack('C*'))  # thumbnail dimensions

      # SOF0 marker (baseline DCT)
      f.write([ 0xFF, 0xC0 ].pack('C*'))
      f.write([ 0x00, 0x11 ].pack('n'))  # Length
      f.write([ 0x08 ].pack('C'))  # Data precision
      f.write([ height ].pack('n'))  # Image height
      f.write([ width ].pack('n'))   # Image width
      f.write([ 0x03 ].pack('C'))  # Number of components
      # Component specifications
      f.write([ 0x01, 0x22, 0x00 ].pack('C*'))  # Y component
      f.write([ 0x02, 0x11, 0x01 ].pack('C*'))  # Cb component
      f.write([ 0x03, 0x11, 0x01 ].pack('C*'))  # Cr component

      # Add minimal scan data
      f.write([ 0xFF, 0xDA ].pack('C*'))  # SOS marker
      f.write([ 0x00, 0x0C ].pack('n'))  # Length
      f.write([ 0x03 ].pack('C'))  # Number of components
      f.write([ 0x01, 0x00 ].pack('C*'))  # Component 1
      f.write([ 0x02, 0x11 ].pack('C*'))  # Component 2
      f.write([ 0x03, 0x11 ].pack('C*'))  # Component 3
      f.write([ 0x00, 0x3F, 0x00 ].pack('C*'))  # Spectral selection

      # Minimal compressed data
      f.write([ 0x00, 0x00 ].pack('C*'))

      # EOI marker
      f.write([ 0xFF, 0xD9 ].pack('C*'))
    end
  end

  # Create a test FHD (1920x1080) image
  def create_test_fhd_image(path)
    create_test_image_with_size(path, 1920, 1080)
  end

  # Create a test HD (1280x720) image
  def create_test_hd_image(path)
    create_test_image_with_size(path, 1280, 720)
  end
end

RSpec.configure do |config|
  config.include TestImageHelper
end
