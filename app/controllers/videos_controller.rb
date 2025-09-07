class VideosController < ApplicationController
  before_action :set_content
  before_action :set_video, only: [ :show, :destroy ]

  def create
    unless @content.video_generation_prerequisites_met?
      missing_prerequisites = @content.video_generation_missing_prerequisites
      redirect_to @content, alert: "動画生成の前提条件が満たされていません: #{missing_prerequisites.join(', ')}"
      return
    end

    if @content.video.present?
      redirect_to @content, alert: "動画は既に存在します。先に削除してから再作成してください。"
      return
    end

    @video = @content.build_video

    if @video.save
      GenerateVideoJob.perform_later(@video.id)
      redirect_to @content, notice: "動画生成を開始しました。処理完了まで数分かかります。"
    else
      redirect_to @content, alert: "動画生成の開始に失敗しました: #{@video.errors.full_messages.join(', ')}"
    end
  end

  def show
    unless @video
      redirect_to @content, alert: "動画が見つかりません。"
      return
    end

    case @video.status.to_sym
    when :pending
      redirect_to @content, notice: "動画生成待機中です。"
    when :processing
      redirect_to @content, notice: "動画生成中です。しばらくお待ちください。"
    when :failed
      redirect_to @content, alert: "動画生成に失敗しました: #{@video.error_message}"
    when :completed
      # Show video download/preview page
      render :show
    else
      redirect_to @content, alert: "動画の状態が不明です。"
    end
  end

  def destroy
    if @video
      @video.destroy
      redirect_to @content, notice: "動画が削除されました。"
    else
      redirect_to @content, alert: "削除する動画が見つかりません。"
    end
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def set_video
    @video = @content.video
  end
end
