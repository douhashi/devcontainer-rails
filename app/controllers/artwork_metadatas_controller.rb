class ArtworkMetadatasController < ApplicationController
  before_action :set_content
  before_action :set_artwork_metadata, only: [ :update, :destroy ]

  def create
    @artwork_metadata = @content.build_artwork_metadata(artwork_metadata_params)

    if @artwork_metadata.save
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: t("artwork_metadata.create.success")
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('artwork_metadata.create.failure')}: #{@artwork_metadata.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    if @artwork_metadata.update(artwork_metadata_params)
      if turbo_request?
        render_turbo_stream_update
      else
        redirect_to @content, notice: t("artwork_metadata.update.success")
      end
    else
      if turbo_request?
        render_turbo_stream_error
      else
        redirect_to @content, alert: "#{t('artwork_metadata.update.failure')}: #{@artwork_metadata.errors.full_messages.join(', ')}"
      end
    end
  end

  def destroy
    if @artwork_metadata&.destroy
      if turbo_request?
        flash.now[:notice] = t("artwork_metadata.delete.success")
        render_turbo_stream_remove
      else
        redirect_to @content, notice: t("artwork_metadata.delete.success"), status: :see_other
      end
    else
      error_message = t("artwork_metadata.delete.failure")
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

  def set_artwork_metadata
    @artwork_metadata = @content.artwork_metadata
    unless @artwork_metadata
      respond_to do |format|
        format.html { head :not_found }
        format.json { render json: { error: "Artwork metadata not found" }, status: :not_found }
        format.any { head :not_found }
      end
      nil
    end
  end

  def artwork_metadata_params
    params.require(:artwork_metadata).permit(:positive_prompt, :negative_prompt)
  end

  def turbo_request?
    request.format.turbo_stream? || request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
  end

  def render_turbo_stream_update
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="artwork-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "artwork_metadata/artwork_metadata_section", locals: { content: @content })}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_remove
    @content.reload  # Ensure content is reloaded after artwork_metadata deletion
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html"
      <turbo-stream action="replace" target="artwork-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "artwork_metadata/artwork_metadata_section", locals: { content: @content })}
        </template>
      </turbo-stream>
    HTML
  end

  def render_turbo_stream_error
    error_messages = @artwork_metadata.errors.full_messages
    render inline: <<~HTML, content_type: "text/vnd.turbo-stream.html", status: :unprocessable_content
      <turbo-stream action="replace" target="artwork-metadata-section-#{@content.id}">
        <template>
          #{render_to_string(partial: "artwork_metadata/error", locals: { content: @content, artwork_metadata: @artwork_metadata, errors: error_messages })}
        </template>
      </turbo-stream>
    HTML
  end
end
