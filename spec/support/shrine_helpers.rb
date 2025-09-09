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
end
