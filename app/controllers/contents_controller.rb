class ContentsController < ApplicationController
  before_action :set_content, only: [ :edit, :update, :destroy, :generate_tracks, :generate_single_track, :generate_audio ]

  def index
    # N+1問題を防ぐためにincludesを使用
    base_query = Content.includes(:tracks, :artwork).order(created_at: :desc)

    # ステータスフィルタリング
    if params[:status].present? && params[:status] != "all"
      @filter_status = params[:status]
      # フィルタリングは後でJavaScriptで行うため、全データを取得
      @contents = base_query
    else
      @filter_status = "all"
      @contents = base_query
    end
  end

  def show
    # 詳細画面では関連データも含めて取得（N+1問題対策）
    @content = Content.includes(
      music_generations: :tracks,
      artwork: {}
    ).find(params[:id])
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(content_params)

    if @content.save
      redirect_to @content, notice: "Content was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @content.update(content_params)
      redirect_to @content, notice: "Content was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @content.destroy!
    redirect_to contents_path, notice: "Content was successfully destroyed."
  end

  def generate_tracks
    # バリデーション
    return redirect_to(@content, alert: "動画の長さが設定されていません") if @content.duration_min.blank? || @content.duration_min <= 0
    return redirect_to(@content, alert: "音楽生成プロンプトが設定されていません") if @content.audio_prompt.blank?

    service = MusicGenerationQueueingService.new(@content)
    recommended_count = service.required_music_generation_count
    music_generations = service.queue_bulk_generation!(recommended_count)

    flash[:success] = "音楽生成を開始しました（#{music_generations.size}件）"
    redirect_to @content
  rescue StandardError => e
    Rails.logger.error "Music generation failed for Content ##{@content.id}: #{e.message}"
    redirect_to @content, alert: "音楽生成の開始に失敗しました: #{e.message}"
  end

  def generate_single_track
    # バリデーション
    return redirect_to(@content, alert: "動画の長さが設定されていません") if @content.duration_min.blank? || @content.duration_min <= 0
    return redirect_to(@content, alert: "音楽生成プロンプトが設定されていません") if @content.audio_prompt.blank?

    service = MusicGenerationQueueingService.new(@content)
    music_generation = service.queue_single_generation!

    flash[:success] = "音楽生成を開始しました（1件）"
    redirect_to @content
  rescue StandardError => e
    Rails.logger.error "Single music generation failed for Content ##{@content.id}: #{e.message}"
    redirect_to @content, alert: "音楽生成の開始に失敗しました: #{e.message}"
  end

  def generate_audio
    # Check prerequisites
    unless audio_generation_prerequisites_met?
      redirect_to @content, alert: audio_generation_error_message
      return
    end

    # Check if audio already exists
    if @content.audio&.completed?
      redirect_to @content, alert: "Audio has already been generated for this content."
      return
    end

    begin
      # Create or update audio record
      audio = @content.audio || @content.build_audio
      audio.status = :pending
      audio.metadata = {}
      audio.save!

      # Queue the generation job
      GenerateAudioJob.perform_later(audio.id)

      Rails.logger.info "Queued audio generation for Content ##{@content.id}"
      redirect_to @content, notice: "Audio generation has been started."
    rescue StandardError => e
      Rails.logger.error "Failed to start audio generation for Content ##{@content.id}: #{e.message}"
      redirect_to @content, alert: "Failed to start audio generation: #{e.message}"
    end
  end

  private

  def set_content
    @content = Content.includes(:tracks, :artwork, :audio).find(params[:id])
  end

  def content_params
    params.require(:content).permit(:theme, :duration_min, :audio_prompt)
  end

  def audio_generation_prerequisites_met?
    return false unless @content.tracks.completed.exists?

    # Check if we have enough completed tracks with duration information
    completed_tracks_count = @content.tracks.completed.where.not(duration_sec: nil).count
    completed_tracks_count >= 2 # Minimum tracks required for audio generation
  end

  def audio_generation_error_message
    errors = []

    unless @content.tracks.completed.exists?
      errors << "No completed tracks available"
    end

    completed_tracks_count = @content.tracks.completed.where.not(duration_sec: nil).count
    if completed_tracks_count < 2
      errors << "At least 2 completed tracks with duration information are required"
    end

    "Audio generation is not available: #{errors.join(', ')}"
  end
end
