require 'fileutils'

# Shrine test helpers
module ShrineHelpers
  def stub_shrine_upload(file_path, mime_type)
    file = File.open(file_path)
    # Ensure the file has the correct MIME type metadata
    uploaded_file = Shrine.upload(file, :cache, metadata: { "mime_type" => mime_type })
    uploaded_file
  end
end

RSpec.configure do |config|
  config.include ShrineHelpers

  # Ensure upload directories exist before running tests
  config.before(:suite) do
    FileUtils.mkdir_p(Rails.root.join('public', 'uploads'))
    FileUtils.mkdir_p(Rails.root.join('public', 'uploads', 'cache'))
    FileUtils.mkdir_p(Rails.root.join('public', 'uploads', 'artworks'))
  end

  # Clean up uploaded files after each test
  # Only clean up for system/request specs to avoid interfering with mocked File operations
  config.after(:each, type: :system) do
    if Rails.root.join('public', 'uploads').exist?
      # Remove all files in uploads directory except cache
      Dir.glob(Rails.root.join('public', 'uploads', '*')).each do |path|
        next if path.include?('cache')
        FileUtils.rm_rf(path)
      end

      # Clean cache directory
      Dir.glob(Rails.root.join('public', 'uploads', 'cache', '*')).each do |path|
        FileUtils.rm_rf(path)
      end
    end
  end

  config.after(:each, type: :request) do
    if Rails.root.join('public', 'uploads').exist?
      # Remove all files in uploads directory except cache
      Dir.glob(Rails.root.join('public', 'uploads', '*')).each do |path|
        next if path.include?('cache')
        FileUtils.rm_rf(path)
      end

      # Clean cache directory
      Dir.glob(Rails.root.join('public', 'uploads', 'cache', '*')).each do |path|
        FileUtils.rm_rf(path)
      end
    end
  end
end
