class ArtworksController < ApplicationController
  before_action :set_content
  before_action :set_artwork, only: [ :update, :destroy, :generate_thumbnail, :regenerate_thumbnail ]
  before_action :authorize_content_management

  def create
    @artwork = @content.build_artwork(artwork_params)

    if @artwork.save
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: "アートワークが正常にアップロードされました。"
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "アートワークのアップロードに失敗しました: #{@artwork.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    if @artwork.update(artwork_params)
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: "アートワークが正常に更新されました。"
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "アートワークの更新に失敗しました: #{@artwork.errors.full_messages.join(', ')}"
      end
    end
  end

  def destroy
    @artwork&.destroy

    if turbo_request?
      render_turbo_stream_remove
    else
      redirect_to @content, notice: "アートワークが削除されました。"
    end
  end

  def generate_thumbnail
    process_thumbnail_generation(regenerate: false)
  end

  def regenerate_thumbnail
    process_thumbnail_generation(regenerate: true)
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def set_artwork
    @artwork = @content.artwork
  end

  def artwork_params
    params.require(:artwork).permit(:image)
  end

  def authorize_content_management
    authorize @content, :manage?
  end

  def turbo_request?
    request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
  end

  def render_turbo_stream_update
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="artwork_#{@content.id}">
        <template>
          #{render_to_string(ArtworkDragDrop::Component.new(content_record: @content))}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_remove
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="artwork_#{@content.id}">
        <template>
          #{render_to_string(partial: "artworks/artwork", locals: { content: @content, artwork: @content.build_artwork })}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_error(errors = nil, status: :unprocessable_content)
    error_messages = errors ? [ errors ] : @artwork.errors.full_messages
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html", status: status
      <turbo-stream action="replace" target="artwork_#{@content.id}">
        <template>
          #{render_to_string(partial: "artworks/error", locals: { content: @content, artwork: @artwork, errors: error_messages })}
        </template>
      </turbo-stream>
    HTML
  end

  def handle_error(message, status: :unprocessable_entity)
    if turbo_request?
      render_turbo_stream_error(message, status: status)
    else
      redirect_to @content, alert: message
    end
  end

  def handle_processing_status
    if turbo_request?
      render_turbo_stream_update
    else
      redirect_to @content, notice: "サムネイル生成は既に実行中です。"
    end
  end

  def handle_ineligible_artwork
    error_message = "このアートワークはYouTube用サムネイル生成の対象外です（1920x1080である必要があります）。"
    handle_error(error_message)
  end

  def process_thumbnail_generation(regenerate: false)
    return handle_error("アートワークが見つかりません。") unless @artwork.present?

    # 再生成の場合のみ処理中チェック
    if regenerate && @artwork.thumbnail_generation_status_processing?
      return handle_processing_status
    end

    # 初回生成時のみ生成済みチェック
    if !regenerate && @artwork.has_youtube_thumbnail?
      return handle_success_message("YouTube用サムネイルは既に生成済みです。", redirect: true)
    end

    return handle_ineligible_artwork unless @artwork.youtube_thumbnail_eligible?

    enqueue_thumbnail_generation(regenerate: regenerate)
  end

  def enqueue_thumbnail_generation(regenerate: false)
    begin
      if regenerate
        @artwork.update!(thumbnail_generation_status: :pending, thumbnail_generation_error: nil)
      end

      DerivativeProcessingJob.perform_later(@artwork)

      message = regenerate ? "再生成を開始しました" : "生成を開始しました"
      handle_success(message)
    rescue => e
      Rails.logger.error "Failed to enqueue thumbnail #{regenerate ? 'regeneration' : 'generation'} for artwork #{@artwork.id}: #{e.message}"
      action = regenerate ? "再生成" : "生成"
      handle_error("サムネイル#{action}の開始に失敗しました: #{e.message}", status: :unprocessable_content)
    end
  end

  def handle_success(message)
    if turbo_request?
      render_turbo_stream_update
    else
      redirect_to @content, notice: "YouTube用サムネイルの#{message}。しばらくお待ちください。"
    end
  end

  def handle_success_message(message, redirect: false)
    if turbo_request? && !redirect
      render_turbo_stream_update
    else
      redirect_to @content, notice: message
    end
  end
end
