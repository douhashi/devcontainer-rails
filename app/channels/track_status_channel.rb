class TrackStatusChannel < ApplicationCable::Channel
  def subscribed
    content = Content.find(params[:content_id])
    stream_for content
    stream_from "content_#{content.id}_tracks"
    stream_from "content_#{content.id}_notifications"
  end

  def unsubscribed
    stop_all_streams
  end
end
