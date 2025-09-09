# frozen_string_literal: true

class PlayButton::Component < ApplicationViewComponent
  option :track
  option :playing, default: proc { false }

  def render?
    track.status.completed? && track.audio.present?
  end

  private

  def button_id
    "play-button-#{track.id}"
  end

  def track_data
    {
      track_id: track.id,
      track_title: track.metadata_title || "Untitled",
      track_url: track.audio.url,
      content_id: track.content&.id,
      content_title: track.content&.theme || "",
      track_list: track_list_json,
      playing: playing
    }
  end

  def track_list_json
    return "[]" unless track.content

    tracks = track.content.tracks
                  .completed
                  .with_audio
                  .order(:created_at)
                  .map do |t|
      {
        id: t.id,
        title: t.metadata_title || "Untitled",
        url: t.audio.url
      }
    end

    tracks.to_json
  end

  def button_classes
    [
      "p-2",
      "rounded-full",
      "transition-all",
      "duration-200",
      "flex",
      "items-center",
      "justify-center",
      playing ? "bg-blue-700" : "bg-blue-600",
      "hover:bg-blue-700",
      "text-white",
      "shadow-sm",
      "hover:shadow-md"
    ].join(" ")
  end
end
