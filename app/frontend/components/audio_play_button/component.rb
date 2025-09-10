# frozen_string_literal: true

class AudioPlayButton::Component < ApplicationViewComponent
  attr_reader :record, :size, :record_type

  def initialize(track: nil, content_record: nil, size: :medium)
    validate_arguments!(track, content_record)

    @record = track || content_record
    @record_type = track ? :track : :content
    @size = size
  end

  def render?
    case record_type
    when :track
      record.status.completed? && record.audio.present?
    when :content
      record.audio.present? && record.audio&.completed? && record.audio&.audio&.present?
    else
      false
    end
  end

  private

  def validate_arguments!(track, content_record)
    if track && content_record
      raise ArgumentError, "Provide either track or content_record, not both"
    end

    unless track || content_record
      raise ArgumentError, "Either track or content_record must be provided"
    end
  end

  def button_id
    "audio-play-button-#{record_type}-#{record.id}"
  end

  def button_variant
    :ghost  # アイコンのみの表示にするためghostバリアントを使用
  end

  def button_size
    :md
  end

  def button_custom_class
    size_classes = case size
    when :small
      "p-1 w-6 h-6"
    when :large
      "p-2 w-10 h-10"
    else
      "p-1.5 w-8 h-8"
    end

    "rounded-full hover:bg-blue-500/20 hover:text-blue-500 transition-all hover:scale-110 #{size_classes}"
  end

  def button_data
    unified_data = {
      controller: "audio-play-button",
      action: "click->audio-play-button#play",
      "audio-play-button-id-value": record.id,
      "audio-play-button-title-value": audio_title,
      "audio-play-button-audio-url-value": audio_url,
      "audio-play-button-type-value": record_type.to_s
    }

    # Add track-specific data
    if record_type == :track && record.content
      unified_data.merge!({
        "audio-play-button-content-id-value": record.content.id,
        "audio-play-button-content-title-value": record.content.theme || "",
        "audio-play-button-track-list-value": track_list_json
      })
    end

    unified_data
  end

  def audio_title
    case record_type
    when :track
      record.metadata_title || "Untitled"
    when :content
      record.theme || "Untitled"
    end
  end

  def audio_url
    case record_type
    when :track
      record.audio.url
    when :content
      record.audio.audio.url
    end
  end

  def track_list_json
    return "[]" unless record_type == :track && record.content

    tracks = record.content.tracks
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

  def icon_size
    case size
    when :small then :sm
    when :large then :lg
    else :md
    end
  end

  def button_aria_label
    "音源を再生: #{audio_title}"
  end
end
