# frozen_string_literal: true

module TestImageHelper
  # Create a test JPEG image with specified dimensions by copying existing valid images
  def create_test_image_with_size(path, width, height)
    # Create directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(path))

    # Use existing valid images based on dimensions
    source_image = case [ width, height ]
    when [ 1920, 1080 ]
                     Rails.root.join('spec/fixtures/files/images/fhd_placeholder.jpg')
    when [ 1280, 720 ]
                     Rails.root.join('spec/fixtures/files/images/hd_placeholder.jpg')
    when [ 640, 480 ]
                     Rails.root.join('spec/fixtures/files/images/sd_placeholder.jpg')
    else
                     # Default to SD image for other sizes
                     Rails.root.join('spec/fixtures/files/images/sd_placeholder.jpg')
    end

    # Copy the source image to destination
    FileUtils.cp(source_image, path)
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
