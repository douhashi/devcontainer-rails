# frozen_string_literal: true

class TrackTable::Preview < ViewComponent::Preview
  def with_tracks
    content = Content.create!(
      theme: "Relaxing Lo-Fi Music",
      duration_min: 60,
      audio_prompt: "Chill lo-fi hip hop beats with soft piano melodies and rain sounds"
    )

    tracks = [
      Track.create!(
        content: content,
        metadata_title: "Morning Coffee",
        status: :completed
      ),
      Track.create!(
        content: content,
        metadata_title: "Study Session",
        status: :processing
      ),
      Track.create!(
        content: content,
        metadata_title: "Rainy Day",
        status: :pending
      )
    ]

    render TrackTable::Component.new(
      tracks: Track.where(id: tracks.map(&:id)),
      show_pagination: true,
      show_content_column: true
    )
  end

  def without_content_column
    content = Content.create!(
      theme: "Focus Music",
      duration_min: 30,
      audio_prompt: "Ambient background music for deep focus"
    )

    tracks = [
      Track.create!(
        content: content,
        metadata_title: "Deep Focus #1",
        status: :completed
      ),
      Track.create!(
        content: content,
        metadata_title: "Deep Focus #2",
        status: :completed
      )
    ]

    render TrackTable::Component.new(
      tracks: Track.where(id: tracks.map(&:id)),
      show_pagination: false,
      show_content_column: false
    )
  end

  def empty_state
    render TrackTable::Component.new(
      tracks: Track.none,
      empty_message: "まだトラックがありません"
    )
  end

  def with_pagination
    content = Content.create!(
      theme: "Productive Beats",
      duration_min: 120,
      audio_prompt: "Upbeat lo-fi beats for productivity"
    )

    # Create 35 tracks to trigger pagination
    35.times do |i|
      Track.create!(
        content: content,
        metadata_title: "Track ##{i + 1}",
        status: [ :pending, :processing, :completed ].sample
      )
    end

    render TrackTable::Component.new(
      tracks: Track.where(content: content).page(1),
      show_pagination: true,
      show_content_column: true
    )
  end
end
