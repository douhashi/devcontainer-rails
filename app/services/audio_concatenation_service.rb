require "shellwords"

class AudioConcatenationService
  class InvalidTracksError < StandardError; end
  class MissingAudioFileError < StandardError; end
  class ConcatenationError < StandardError; end

  attr_reader :tracks

  def initialize(tracks)
    @tracks = tracks
    validate_tracks!
  end

  def concatenate(output_path)
    validate_audio_files!

    Rails.logger.info "Starting audio concatenation for #{tracks.count} tracks"

    playlist_path = create_playlist_file

    begin
      ffmpeg_command = build_ffmpeg_command(playlist_path, output_path)
      success = system(ffmpeg_command)

      unless success
        raise ConcatenationError, "Failed to concatenate audio files. FFmpeg command failed."
      end

      Rails.logger.info "Audio concatenation completed: #{output_path}"
      output_path
    ensure
      File.unlink(playlist_path) if playlist_path && File.exist?(playlist_path)
    end
  end

  private

  def validate_tracks!
    if tracks.nil? || tracks.empty?
      raise InvalidTracksError, "No tracks provided for concatenation"
    end
  end

  def validate_audio_files!
    tracks.each do |track|
      unless track.audio&.file
        raise MissingAudioFileError, "Track ##{track.id} has no audio file attached"
      end
    end
  end

  def create_playlist_file
    playlist_file = Tempfile.new([ "playlist", ".txt" ])

    tracks.each do |track|
      audio_path = track.audio.file.path
      # Sanitize path in playlist file to prevent injection attacks
      sanitized_path = audio_path.gsub("'", "\\'")
      playlist_file.puts("file '#{sanitized_path}'")
    end

    playlist_file.close
    playlist_file.path
  end

  def build_ffmpeg_command(playlist_path, output_path)
    # Use ffmpeg concat demuxer with copy codec for fast concatenation
    # -f concat: use concat demuxer
    # -safe 0: allow absolute paths
    # -i: input playlist file
    # -c copy: copy streams without re-encoding (faster)
    # -y: overwrite output file if exists
    # Sanitize all path arguments to prevent command injection
    safe_playlist_path = Shellwords.escape(playlist_path)
    safe_output_path = Shellwords.escape(output_path)
    "ffmpeg -f concat -safe 0 -i #{safe_playlist_path} -c copy -y #{safe_output_path}"
  end
end
