require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads")
}

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :validation_helpers
Shrine.plugin :derivatives
Shrine.plugin :backgrounding

# Use custom MIME type detection for better compatibility
if Rails.env.test?
  Shrine.plugin :determine_mime_type, analyzer: ->(io, analyzers) do
    # Try marcel first
    mime_type = analyzers[:marcel].call(io) rescue nil

    # Fallback to file extension for test fixtures if marcel fails or returns generic type
    if mime_type.nil? || mime_type == "application/octet-stream"
      filename = io.respond_to?(:original_filename) ? io.original_filename : (io.respond_to?(:path) ? File.basename(io.path) : "")

      case File.extname(filename).downcase
      when ".mp3"
        "audio/mpeg"
      when ".wav"
        "audio/wav"
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".png"
        "image/png"
      else
        mime_type || "application/octet-stream"
      end
    else
      mime_type
    end
  end
else
  Shrine.plugin :determine_mime_type, analyzer: :marcel
end

# Configure backgrounding for derivative processing
# This will be handled directly in the Artwork model after save callback
