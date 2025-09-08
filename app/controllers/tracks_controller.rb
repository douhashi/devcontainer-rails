class TracksController < ApplicationController
  before_action :set_content, except: [ :index ]

  def index
    @q = Track.joins(:content).ransack(params[:q])
    @tracks = @q.result
                .includes(:content)
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
    recommended_count = service.required_music_generation_count
    music_generations = service.queue_bulk_generation!(recommended_count)

    flash[:success] = "音楽生成を開始しました（#{music_generations.size}件）"
    redirect_to content_path(@content)
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end
end
