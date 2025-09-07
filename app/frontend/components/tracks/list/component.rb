# frozen_string_literal: true

class Tracks::List::Component < ApplicationViewComponent
  attr_reader :tracks

  def initialize(tracks:)
    @tracks = tracks
  end

  private

  def status_badge_class(track)
    if track.status.pending?
      "bg-yellow-500 text-white"
    elsif track.status.processing?
      "bg-blue-500 text-white"
    elsif track.status.completed?
      "bg-green-500 text-white"
    elsif track.status.failed?
      "bg-red-500 text-white"
    else
      "bg-gray-500 text-white"
    end
  end

  def status_text(track)
    if track.status.pending?
      "待機中"
    elsif track.status.processing?
      "生成中"
    elsif track.status.completed?
      "完了"
    elsif track.status.failed?
      "失敗"
    else
      "不明"
    end
  end

  def has_audio?(track)
    track.status.completed? && track.audio.present?
  end

  def formatted_created_at(track)
    track.created_at.strftime("%Y/%m/%d %H:%M")
  end

  def ordered_tracks
    if tracks.respond_to?(:order)
      tracks.order(:created_at)
    else
      tracks.sort_by(&:created_at)
    end
  end
end
