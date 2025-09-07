class ImageUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/gif]
    validate_max_size 10.megabytes
  end

  def generate_location(io, record: nil, **context)
    if record
      "artworks/#{record.id}/#{super}"
    else
      super
    end
  end
end
