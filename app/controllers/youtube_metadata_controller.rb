class YoutubeMetadataController < ApplicationController
  before_action :set_content
  before_action :set_youtube_metadata, only: [ :update, :destroy ]

  def create
    @youtube_metadata = @content.build_youtube_metadata(youtube_metadata_params)

    if @youtube_metadata.save
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: t("youtube_metadata.create.success")
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('youtube_metadata.create.failure')}: #{@youtube_metadata.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    if @youtube_metadata.update(youtube_metadata_params)
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: t("youtube_metadata.update.success")
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('youtube_metadata.update.failure')}: #{@youtube_metadata.errors.full_messages.join(', ')}"
      end
    end
  end

  def destroy
    if @youtube_metadata&.destroy
      if turbo_request?
        flash.now[:notice] = t("youtube_metadata.delete.success")
        render_turbo_stream_remove
      else
        redirect_to @content, notice: t("youtube_metadata.delete.success"), status: :see_other
      end
    else
      error_message = t("youtube_metadata.delete.failure")
      if turbo_request?
        flash.now[:alert] = error_message
        render_turbo_stream_remove
      else
        redirect_to @content, alert: error_message, status: :see_other
      end
    end
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def set_youtube_metadata
    @youtube_metadata = @content.youtube_metadata
    unless @youtube_metadata
      respond_to do |format|
        format.html { head :not_found }
        format.json { render json: { error: "YouTube metadata not found" }, status: :not_found }
        format.any { head :not_found }
      end
      nil
    end
  end

  def youtube_metadata_params
    params.require(:youtube_metadata).permit(:title, :description_en, :description_ja, :hashtags, :status)
  end

  def turbo_request?
    request.format.turbo_stream? || request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
  end

  def render_turbo_stream_update
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="youtube-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "youtube_metadata/youtube_metadata_section", locals: { content: @content })}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_remove
    @content.reload  # Ensure content is reloaded after youtube_metadata deletion
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="youtube-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "youtube_metadata/youtube_metadata_section", locals: { content: @content })}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_error
    error_messages = @youtube_metadata.errors.full_messages
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html", status: :unprocessable_content
      <turbo-stream action="replace" target="youtube-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "youtube_metadata/error", locals: { content: @content, youtube_metadata: @youtube_metadata, errors: error_messages })}
        </template>
      </turbo-stream>
    HTML
  end
end
