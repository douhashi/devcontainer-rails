class AudioUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type %w[audio/mpeg audio/wav audio/x-wav]
    validate_max_size 100.megabytes
  end

  def generate_location(io, record: nil, **context)
    if record
      "tracks/#{record.id}/#{super}"
    else
      super
    end
  end
end
