class MusicGenerationsController < ApplicationController
  before_action :set_content
  before_action :set_music_generation, only: [ :destroy ]

  def destroy
    @music_generation.destroy!
    redirect_to @content, notice: "音楽生成が削除されました。"
  end

  private

  def set_content
    @content = Content.find(params[:content_id])
  end

  def set_music_generation
    @music_generation = @content.music_generations.find(params[:id])
  end
end
