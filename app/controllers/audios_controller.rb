class AudiosController < ApplicationController
  before_action :set_content
  before_action :set_audio, only: [ :destroy ]

  def destroy
    if @audio
      @audio.destroy
      redirect_to @content, notice: "音源が削除されました。"
    else
      redirect_to @content, alert: "削除する音源が見つかりません。"
    end
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def set_audio
    @audio = @content.audio
  end
end
