# frozen_string_literal: true

class TrackDetail::Component < ApplicationViewComponent
  attr_reader :track

  def initialize(track:)
    @track = track
  end

  def render?
    track.present? && track.has_metadata?
  end

  def formatted_tags
    return nil unless track.metadata_tags.present?

    track.metadata_tags.split(",").map(&:strip).join(", ")
  end

  def truncated_prompt
    return nil unless track.metadata_generated_prompt.present?

    track.metadata_generated_prompt.truncate(200)
  end
end
