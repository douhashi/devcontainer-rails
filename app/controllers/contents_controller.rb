class ContentsController < ApplicationController
  before_action :set_content, only: [ :show, :edit, :update, :destroy ]

  def index
    @contents = Content.all
  end

  def show
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

  private

  def set_content
    @content = Content.find(params[:id])
  end

  def content_params
    params.require(:content).permit(:theme, :duration, :audio_prompt)
  end
end
