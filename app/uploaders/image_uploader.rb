class ImageUploader < Shrine
  plugin :validation_helpers
  plugin :derivatives

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/gif]
    validate_max_size 10.megabytes
  end

  # Define derivatives processing
  Attacher.derivatives do |original|
    youtube_thumbnail = nil

    # Check if the original image is eligible for YouTube thumbnail generation
    if original.metadata && original.metadata["width"] == 1920 && original.metadata["height"] == 1080
      # This will be processed asynchronously via DerivativeProcessingJob
      # We don't process here, just return empty hash
      {}
    else
      {}
    end
  end

  def generate_location(io, record: nil, derivative: nil, **context)
    if record
      if derivative
        "artworks/#{record.id}/derivatives/#{derivative}/#{super}"
      else
        "artworks/#{record.id}/#{super}"
      end
    else
      super
    end
  end
end
