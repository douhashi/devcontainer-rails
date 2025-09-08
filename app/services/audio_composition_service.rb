class AudioCompositionService
  class InsufficientTracksError < StandardError; end

  attr_reader :content

  def initialize(content)
    @content = content
  end

  def select_tracks
    target_duration = content.duration_min * 60 # Convert minutes to seconds
    tracks = available_tracks

    raise InsufficientTracksError, "No completed tracks available" if tracks.empty?

    # Pre-calculate if we have enough total duration
    total_available_duration = tracks.sum(:duration_sec)
    if total_available_duration < target_duration
      raise InsufficientTracksError, "Insufficient total track duration: #{total_available_duration}s available, #{target_duration}s needed"
    end

    selected_tracks = []
    total_duration = 0

    # More efficient selection algorithm for large datasets
    # Convert to array once to avoid multiple DB calls
    track_array = tracks.pluck(:id, :duration_sec).map { |id, duration_sec| { id: id, duration: duration_sec } }

    # Shuffle for random selection
    track_array.shuffle!

    # Batch process tracks with early termination
    track_array.each do |track_data|
      # Early termination if target is reached
      break if total_duration >= target_duration

      # Load actual track object only when needed (lazy loading)
      track = tracks.find(track_data[:id])
      selected_tracks << track
      total_duration += track_data[:duration]
    end

    # Final validation
    if total_duration < target_duration
      raise InsufficientTracksError, "Insufficient track duration after selection: #{total_duration}s selected, #{target_duration}s needed"
    end

    result = {
      selected_tracks: selected_tracks,
      total_duration: total_duration,
      tracks_used: selected_tracks.count,
      target_duration: target_duration
    }

    Rails.logger.info "Selected #{result[:tracks_used]} tracks for Content ##{content.id}: #{result[:total_duration]}s total (target: #{result[:target_duration]}s) from #{track_array.size} available"

    result
  end

  private

  def available_tracks
    @available_tracks ||= content.tracks.completed.where.not(duration_sec: nil)
  end
end
