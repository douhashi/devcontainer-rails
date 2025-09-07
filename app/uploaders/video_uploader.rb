class VideoUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type %w[video/mp4]
    validate_max_size 500.megabytes
  end

  def generate_location(io, record: nil, **context)
    if record
      "videos/#{record.id}/#{super}"
    else
      super
    end
  end
end
