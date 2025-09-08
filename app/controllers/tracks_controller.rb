class TracksController < ApplicationController
  before_action :set_content, except: [ :index ]

  def index
    search_params_with_date_fix = search_params_with_end_of_day
    @q = Track.joins(:content).ransack(search_params_with_date_fix)
    @tracks = @q.result
                .includes(:content)
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

  def search_params
    params[:q]&.permit(:content_theme_cont, :music_title_cont, :status_eq,
                       :created_at_gteq, :created_at_lteq, :created_at_lt,
                       :created_at_lteq_end_of_day, :s)
  end

  def search_params_with_end_of_day
    return nil unless params[:q]

    search_hash = search_params&.to_h
    return search_hash unless search_hash

    # Convert created_at_lteq to end of day for inclusive search
    if search_hash["created_at_lteq"].present?
      date = Date.parse(search_hash["created_at_lteq"])
      search_hash["created_at_lt"] = (date + 1.day).to_s
      search_hash.delete("created_at_lteq")
    end

    search_hash
  end
end
