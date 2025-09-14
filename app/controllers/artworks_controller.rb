require "timeout"

class ArtworksController < ApplicationController
  before_action :set_content
  before_action :set_artwork, only: [ :update, :destroy, :generate_thumbnail, :regenerate_thumbnail ]
  before_action :authorize_content_management

  def create
    @artwork = @content.build_artwork(artwork_params)

    if @artwork.save
      # 同期的にサムネイル生成を実行（1920x1080の場合のみ）
      if @artwork.youtube_thumbnail_eligible?
        generate_thumbnail_sync
      else
        if turbo_request?
          render_turbo_stream_update
        else
          redirect_to @content, notice: t("artworks.upload.success")
        end
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('artworks.upload.failure')}: #{@artwork.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    if @artwork.update(artwork_params)
      # 同期的にサムネイル生成を実行（1920x1080の場合のみ）
      if @artwork.youtube_thumbnail_eligible?
        generate_thumbnail_sync
      else
        if turbo_request?
          render_turbo_stream_update
        else
          redirect_to @content, notice: t("artworks.update.success")
        end
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('artworks.update.failure')}: #{@artwork.errors.full_messages.join(', ')}"
      end
    end
  end

  def destroy
    @artwork&.destroy

    if turbo_request?
      render_turbo_stream_remove
    else
      redirect_to @content, notice: t("artworks.delete.success")
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

  def handle_error(message, status: :unprocessable_content)
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
      redirect_to @content, notice: t("artworks.thumbnail.processing")
    end
  end

  def handle_ineligible_artwork
    error_message = t("artworks.thumbnail.not_eligible")
    handle_error(error_message)
  end

  def process_thumbnail_generation(regenerate: false)
    return handle_error(t("artworks.thumbnail.not_found")) unless @artwork.present?

    # 再生成の場合のみ処理中チェック
    if regenerate && @artwork.thumbnail_generation_status_processing?
      return handle_processing_status
    end

    # 初回生成時のみ生成済みチェック
    if !regenerate && @artwork.has_youtube_thumbnail?
      return handle_success_message(t("artworks.thumbnail.already_exists"), redirect: true)
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

      message = regenerate ? t("artworks.thumbnail.regeneration_started") : t("artworks.thumbnail.generation_started")
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
      redirect_to @content, notice: message
    end
  end

  def handle_success_message(message, redirect: false)
    if turbo_request? && !redirect
      render_turbo_stream_update
    else
      redirect_to @content, notice: message
    end
  end

  def generate_thumbnail_sync
    output_file = nil

    begin
      @artwork.mark_thumbnail_generation_started!
      Rails.logger.info "Starting synchronous thumbnail generation for artwork #{@artwork.id}"

      # タイムアウト設定（30秒）
      Timeout.timeout(30) do
        # Shrineから直接ファイルを開いてサムネイル生成
        @artwork.image.open do |image_file|
          Rails.logger.info "Opened image file: #{image_file.path} (size: #{File.size(image_file.path)} bytes)"
          service = ThumbnailGenerationService.new
          output_file = Tempfile.new([ "youtube_thumbnail_#{@artwork.id}", ".jpg" ])

          begin
            result = service.generate(
              input_path: image_file.path,
              output_path: output_file.path
            )

            # サムネイルをderivativesとして保存
            File.open(output_file.path) do |file|
              attacher = @artwork.image_attacher
              derivatives = { youtube_thumbnail: attacher.upload(file, :store) }
              attacher.set_derivatives(derivatives)
              @artwork.save!
            end

            @artwork.mark_thumbnail_generation_completed!

            message = t("artworks.upload.success_with_thumbnail")
            if turbo_request?
              render_turbo_stream_update
            else
              redirect_to @content, notice: message
            end
          rescue => inner_error
            # 内部処理でエラーが発生した場合は再発生させる
            raise inner_error
          end
        end
      end
    rescue Timeout::Error
      @artwork.mark_thumbnail_generation_failed!("Thumbnail generation timeout (30s)")
      handle_error(t("artworks.thumbnail.generation_timeout"))
    rescue ThumbnailGenerationService::GenerationError => e
      Rails.logger.error "Thumbnail generation failed with GenerationError: #{e.message}"
      @artwork.mark_thumbnail_generation_failed!(e.message)
      handle_error("#{t('artworks.thumbnail.generation_failed')}: #{e.message}")
    rescue => e
      error_details = {
        artwork_id: @artwork.id,
        artwork_dimensions: artwork_dimensions,
        file_size: file_size_mb,
        error_class: e.class.name,
        error_message: e.message,
        vips_available: defined?(Vips) ? "yes" : "no"
      }

      Rails.logger.error "Failed to generate thumbnail: #{error_details.to_json}"
      Rails.logger.error e.backtrace.join("\n")
      @artwork.mark_thumbnail_generation_failed!("#{e.class}: #{e.message}")
      handle_error(t("artworks.thumbnail.generation_error"))
    ensure
      # 一時ファイルの確実なクリーンアップ
      if output_file
        begin
          output_file.close unless output_file.closed?
          output_file.unlink if output_file.path && File.exist?(output_file.path)
        rescue => cleanup_error
          Rails.logger.warn "Failed to cleanup temporary file: #{cleanup_error.message}"
        end
      end

      # Vipsのメモリ解放
      GC.start if defined?(Vips)
    end
  end

  private

  def artwork_dimensions
    return "unknown" unless @artwork&.image

    begin
      @artwork.image.open do |file|
        if defined?(Vips)
          img = Vips::Image.new_from_file(file.path)
          "#{img.width}x#{img.height}"
        else
          "unknown"
        end
      end
    rescue
      "unknown"
    end
  end

  def file_size_mb
    return "unknown" unless @artwork&.image

    begin
      size_bytes = @artwork.image.size
      "#{(size_bytes / 1_048_576.0).round(2)}MB"
    rescue
      "unknown"
    end
  end
end
