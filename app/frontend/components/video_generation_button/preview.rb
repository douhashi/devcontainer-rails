# frozen_string_literal: true

class VideoGenerationButton::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  # self.container_class = "w-1/2 border border-gray-300"

  def default
    content = Content.new(id: 1, theme: "Test Content")
    content.define_singleton_method(:video_generation_prerequisites_met?) { true }
    content.define_singleton_method(:video_generation_missing_prerequisites) { [] }
    content.define_singleton_method(:video) { nil }
    render VideoGenerationButton::Component.new(content_record: content)
  end

  def completed
    content = Content.new(id: 1, theme: "Test Content")
    video = Video.new(id: 1, content: content, status: :completed, created_at: 1.hour.ago)
    video.define_singleton_method(:persisted?) { true }
    video.define_singleton_method(:video) do
      video_file = Object.new
      video_file.define_singleton_method(:present?) { true }
      video_file.define_singleton_method(:url) { "/videos/test.mp4" }
      video_file
    end
    content.define_singleton_method(:video) { video }
    content.define_singleton_method(:video_generation_prerequisites_met?) { true }
    content.define_singleton_method(:video_generation_missing_prerequisites) { [] }
    render VideoGenerationButton::Component.new(content_record: content)
  end

  def processing
    content = Content.new(id: 1, theme: "Test Content")
    video = Video.new(id: 1, content: content, status: :processing, created_at: 30.minutes.ago)
    video.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:video) { video }
    content.define_singleton_method(:video_generation_prerequisites_met?) { true }
    content.define_singleton_method(:video_generation_missing_prerequisites) { [] }
    render VideoGenerationButton::Component.new(content_record: content)
  end

  def failed
    content = Content.new(id: 1, theme: "Test Content")
    video = Video.new(id: 1, content: content, status: :failed, created_at: 2.hours.ago)
    video.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:video) { video }
    content.define_singleton_method(:video_generation_prerequisites_met?) { true }
    content.define_singleton_method(:video_generation_missing_prerequisites) { [] }
    render VideoGenerationButton::Component.new(content_record: content)
  end
end
