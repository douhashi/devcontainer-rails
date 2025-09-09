# frozen_string_literal: true

class EmptyTrackRow::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  self.container_class = "w-full"

  def default
    render(EmptyTrackRow::Component.new(
      music_generation: music_generation
    ))
  end

  private

  def music_generation
    OpenStruct.new(
      id: 42,
      status: :pending,
      prompt: "Generate lo-fi beats",
      created_at: Time.current
    )
  end
end
