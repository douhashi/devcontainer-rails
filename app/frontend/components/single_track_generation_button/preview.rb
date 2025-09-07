# frozen_string_literal: true

class SingleTrackGenerationButton::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  # self.container_class = "w-1/2 border border-gray-300"

  def default
    content = FactoryBot.create(:content, duration: 10, audio_prompt: "Lo-fi hip hop beat")
    render SingleTrackGenerationButton::Component.new(content_record: content)
  end

  def with_processing_track
    content = FactoryBot.create(:content, duration: 10, audio_prompt: "Lo-fi hip hop beat")
    FactoryBot.create(:track, content: content, status: :processing)
    render SingleTrackGenerationButton::Component.new(content_record: content)
  end

  def with_max_tracks
    content = FactoryBot.create(:content, duration: 10, audio_prompt: "Lo-fi hip hop beat")
    FactoryBot.create_list(:track, 100, content: content)
    render SingleTrackGenerationButton::Component.new(content_record: content)
  end

  def with_99_tracks
    content = FactoryBot.create(:content, duration: 10, audio_prompt: "Lo-fi hip hop beat")
    FactoryBot.create_list(:track, 99, content: content)
    render SingleTrackGenerationButton::Component.new(content_record: content)
  end
end
