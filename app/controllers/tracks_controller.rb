class TracksController < ApplicationController
  before_action :set_content, except: [ :index ]

  def index
    @tracks = Track.includes(:content)
                   .recent
                   .page(params[:page])
                   .per(30)
  end

  def generate_single
    # Deprecated: Use MusicGenerationQueueingService instead
    Rails.logger.warn "TracksController#generate_single is deprecated. Use MusicGenerationQueueingService instead."

    service = MusicGenerationQueueingService.new(@content)
    created_generations = service.queue_music_generations!

    if created_generations.any?
      flash[:success] = "音楽生成を開始しました（#{created_generations.size}件）"
    else
      flash[:info] = "すでに必要な音楽生成が完了またはキューに入っています"
    end

    redirect_to content_path(@content)
  end

  def generate_bulk
    # Deprecated: Use MusicGenerationQueueingService instead
    Rails.logger.warn "TracksController#generate_bulk is deprecated. Use MusicGenerationQueueingService instead."

    service = MusicGenerationQueueingService.new(@content)
    created_generations = service.queue_music_generations!

    if created_generations.any?
      flash[:success] = "音楽生成を開始しました（#{created_generations.size}件）"
    else
      flash[:info] = "すでに必要な音楽生成が完了またはキューに入っています"
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
