# frozen_string_literal: true

class ExtendedTrackRow::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  self.container_class = "w-full"

  def default
    render(ExtendedTrackRow::Component.new(
      track: track,
      music_generation: music_generation,
      is_group_start: true,
      group_size: 1
    ))
  end

  def grouped_first_track
    render(ExtendedTrackRow::Component.new(
      track: track,
      music_generation: music_generation,
      is_group_start: true,
      group_size: 3
    ))
  end

  def grouped_middle_track
    render(ExtendedTrackRow::Component.new(
      track: track(status: :processing),
      music_generation: music_generation,
      is_group_start: false,
      group_size: 0
    ))
  end

  def grouped_last_track
    render(ExtendedTrackRow::Component.new(
      track: track(status: :completed, duration_sec: 180),
      music_generation: music_generation,
      is_group_start: false,
      group_size: 0
    ))
  end

  private

  def track(status: :completed, duration_sec: 120)
    track = OpenStruct.new(
      id: rand(1..100),
      duration_sec: duration_sec,
      audio: status == :completed ? OpenStruct.new(file: OpenStruct.new(url: "/sample.mp3")) : nil,
      content_id: 1,
      content: OpenStruct.new(id: 1),  # contentオブジェクトを追加
      music_generation_id: 1,
      formatted_duration: format_duration(duration_sec)
    )

    # statusをActiveRecordのenumのように振る舞わせる
    track.status = OpenStruct.new(
      to_s: status.to_s,
      completed?: status == :completed,
      processing?: status == :processing,
      pending?: status == :pending,
      failed?: status == :failed
    )

    track
  end

  def music_generation
    OpenStruct.new(
      id: 2,
      status: :completed,
      prompt: "Generate lo-fi hip hop beats",
      created_at: Time.current
    )
  end

  def format_duration(duration_sec)
    return "未取得" if duration_sec.nil?

    total_seconds = duration_sec
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60

    if hours > 0
      format("%d:%02d:%02d", hours, minutes, seconds)
    else
      format("%d:%02d", minutes, seconds)
    end
  end
end
