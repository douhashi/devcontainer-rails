# frozen_string_literal: true

class InlineAudioPlayer::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  self.container_class = "w-full max-w-4xl p-8 bg-gray-900"

  def default
    render(InlineAudioPlayer::Component.new(track: completed_track_with_audio))
  end

  def with_track_small
    render(InlineAudioPlayer::Component.new(track: completed_track_with_audio, size: :small))
  end

  def with_track_medium
    render(InlineAudioPlayer::Component.new(track: completed_track_with_audio, size: :medium))
  end

  def with_track_large
    render(InlineAudioPlayer::Component.new(track: completed_track_with_audio, size: :large))
  end

  def with_content_record
    render(InlineAudioPlayer::Component.new(content_record: content_with_audio))
  end

  def multiple_players
    render_with_template(
      locals: {
        tracks: [
          completed_track_with_audio,
          completed_track_with_audio_2,
          completed_track_with_audio_3
        ]
      }
    )
  end

  private

  def completed_track_with_audio
    Track.new(
      id: 1,
      status: "completed",
      metadata: { "music_title" => "Lofi Hip Hop Beat #1" },
      created_at: Time.current
    ).tap do |track|
      track.define_singleton_method(:audio) do
        OpenStruct.new(
          present?: true,
          url: "https://example.com/audio1.mp3"
        )
      end
      track.define_singleton_method(:status) do
        OpenStruct.new(completed?: true, processing?: false)
      end
    end
  end

  def completed_track_with_audio_2
    Track.new(
      id: 2,
      status: "completed",
      metadata_title: "Chill Study Music",
      created_at: Time.current
    ).tap do |track|
      track.define_singleton_method(:audio) do
        OpenStruct.new(
          present?: true,
          url: "https://example.com/audio2.mp3"
        )
      end
      track.define_singleton_method(:status) do
        OpenStruct.new(completed?: true, processing?: false)
      end
    end
  end

  def completed_track_with_audio_3
    Track.new(
      id: 3,
      status: "completed",
      metadata_title: "Rainy Day Vibes",
      created_at: Time.current
    ).tap do |track|
      track.define_singleton_method(:audio) do
        OpenStruct.new(
          present?: true,
          url: "https://example.com/audio3.mp3"
        )
      end
      track.define_singleton_method(:status) do
        OpenStruct.new(completed?: true, processing?: false)
      end
    end
  end

  def content_with_audio
    Content.new(
      id: 1,
      theme: "Relaxing Piano Music"
    ).tap do |content|
      content.define_singleton_method(:audio) do
        OpenStruct.new(
          present?: true,
          completed?: true,
          audio: OpenStruct.new(
            present?: true,
            url: "https://example.com/content-audio.mp3"
          )
        )
      end
    end
  end
end
