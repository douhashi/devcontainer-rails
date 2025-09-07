class TracksController < ApplicationController
  before_action :set_content

  def generate_single
    if can_generate_more?
      track = @content.tracks.create!(status: :pending)
      track.generate_audio!

      flash[:success] = "Track生成を開始しました"
    else
      flash[:error] = "生成上限に達しています"
    end

    redirect_to content_path(@content)
  end

  def generate_bulk
    if can_generate_more?
      tracks_to_generate = [ remaining_tracks, 10 ].min

      tracks_to_generate.times do
        track = @content.tracks.create!(status: :pending)
        track.generate_audio!
      end

      flash[:success] = "#{tracks_to_generate}件のTrack生成を開始しました"
    else
      flash[:error] = "生成上限に達しています"
    end

    redirect_to content_path(@content)
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def can_generate_more?
    @content.tracks.count < 100
  end

  def remaining_tracks
    100 - @content.tracks.count
  end
end
