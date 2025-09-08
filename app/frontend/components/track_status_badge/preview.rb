# frozen_string_literal: true

class TrackStatusBadge::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  # self.container_class = "w-1/2 border border-gray-300"

  def all_statuses
    render_with_template template: "track_status_badge/all_statuses"
  end

  def pending
    track = build(:track, :pending)
    render TrackStatusBadge::Component.new(track: track)
  end

  def processing
    track = build(:track, :processing)
    render TrackStatusBadge::Component.new(track: track)
  end

  def completed
    track = build(:track, :completed)
    render TrackStatusBadge::Component.new(track: track)
  end

  def failed
    track = build(:track, :failed)
    render TrackStatusBadge::Component.new(track: track)
  end
end
