# frozen_string_literal: true

class InlineAudioPlayer::Component < ApplicationViewComponent
  attr_reader :record, :size, :record_type

  def initialize(track: nil, content_record: nil, size: :medium)
    validate_arguments!(track, content_record)

    @record = track || content_record
    @record_type = track ? :track : :content
    @size = size
  end

  # Alias for compatibility with tests
  def track
    record_type == :track ? record : nil
  end

  # Alias for compatibility with tests
  def content_record
    record_type == :content ? record : nil
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

  def player_id
    "inline-audio-player-#{record_type}-#{record.id}"
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
      record.audio&.audio&.url
    end
  end

  def player_size_class
    case size
    when :small
      "h-8"
    when :large
      "h-12"
    else
      "h-10"
    end
  end

  def controls_size_class
    case size
    when :small
      "text-xs"
    when :large
      "text-base"
    else
      "text-sm"
    end
  end

  def stimulus_data
    {
      controller: "inline-audio-player",
      "inline-audio-player-id-value": record.id,
      "inline-audio-player-type-value": record_type.to_s,
      "inline-audio-player-title-value": audio_title,
      "inline-audio-player-url-value": audio_url
    }
  end
end
