class TracksController < ApplicationController
  before_action :set_content, except: [ :index ]

  def index
    @tracks = Track.includes(:content)
                   .recent
                   .page(params[:page])
                   .per(30)
  end

  def generate_single
    service = MusicGenerationQueueingService.new(@content)
    music_generation = service.queue_single_generation!

    flash[:success] = "音楽生成を開始しました（1件）"
    redirect_to content_path(@content)
  end

  def generate_bulk
    service = MusicGenerationQueueingService.new(@content)
    music_generations = service.queue_bulk_generation!(5)

    flash[:success] = "音楽生成を開始しました（5件）"
    redirect_to content_path(@content)
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end
end
