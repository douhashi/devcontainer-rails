class ArtworksController < ApplicationController
  before_action :set_content
  before_action :set_artwork, only: [ :update, :destroy, :generate_thumbnail ]
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
    unless @artwork.present?
      redirect_to @content, alert: "アートワークが見つかりません。"
      return
    end

    if @artwork.has_youtube_thumbnail?
      redirect_to @content, notice: "YouTube用サムネイルは既に生成済みです。"
      return
    end

    unless @artwork.youtube_thumbnail_eligible?
      redirect_to @content, alert: "このアートワークはYouTube用サムネイル生成の対象外です（1920x1080である必要があります）。"
      return
    end

    begin
      DerivativeProcessingJob.perform_later(@artwork)
      redirect_to @content, notice: "YouTube用サムネイルの生成を開始しました。しばらくお待ちください。"
    rescue => e
      Rails.logger.error "Failed to enqueue thumbnail generation for artwork #{@artwork.id}: #{e.message}"
      redirect_to @content, alert: "サムネイル生成の開始に失敗しました: #{e.message}"
    end
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
          #{render_to_string(partial: "artworks/artwork", locals: { content: @content, artwork: @artwork })}
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

  def render_turbo_stream_error
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html", status: :unprocessable_content
      <turbo-stream action="replace" target="artwork_#{@content.id}">
        <template>
          #{render_to_string(partial: "artworks/error", locals: { content: @content, artwork: @artwork, errors: @artwork.errors.full_messages })}
        </template>
      </turbo-stream>
    HTML
  end
end
