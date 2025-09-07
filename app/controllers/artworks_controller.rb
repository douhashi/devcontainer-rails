class ArtworksController < ApplicationController
  before_action :set_content

  def create
    @artwork = @content.build_artwork(artwork_params)

    if @artwork.save
      redirect_to @content, notice: "アートワークが正常にアップロードされました。"
    else
      redirect_to @content, alert: "アートワークのアップロードに失敗しました: #{@artwork.errors.full_messages.join(', ')}"
    end
  end

  def update
    @artwork = @content.artwork

    if @artwork.update(artwork_params)
      redirect_to @content, notice: "アートワークが正常に更新されました。"
    else
      redirect_to @content, alert: "アートワークの更新に失敗しました: #{@artwork.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @artwork = @content.artwork
    @artwork&.destroy
    redirect_to @content, notice: "アートワークが削除されました。"
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def artwork_params
    params.require(:artwork).permit(:image)
  end
end
