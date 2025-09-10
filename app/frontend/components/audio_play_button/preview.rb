# frozen_string_literal: true

# Mock relation for preview
class MockRelation
  def initialize(data)
    @data = data
  end

  def completed
    self
  end

  def with_audio
    self
  end

  def order(*)
    self
  end

  def map(&block)
    @data.map(&block)
  end
end

class AudioPlayButton::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  self.container_class = "p-8 bg-gray-900"

  def default
    # Create test track with audio
    track = Track.new(
      id: 1,
      status: "completed"
    )

    # Mock metadata_title
    track.define_singleton_method(:metadata_title) do
      "Test Track"
    end

    # Mock the audio attachment
    track.define_singleton_method(:audio) do
      OpenStruct.new(
        present?: true,
        url: "/test/audio.mp3"
      )
    end

    # Mock the content
    track.define_singleton_method(:content) do
      content = OpenStruct.new(
        id: 100,
        theme: "Test Theme"
      )

      # Mock tracks relation
      content.define_singleton_method(:tracks) do
        # Return a mock relation that responds to chaining methods
        MockRelation.new([])
      end

      content
    end

    render(AudioPlayButton::Component.new(track: track))
  end

  def with_content
    # Create test content with audio
    content = Content.new(
      id: 2,
      theme: "Test Content Theme"
    )

    # Mock the audio attachment
    audio = OpenStruct.new(
      present?: true,
      completed?: true,
      audio: OpenStruct.new(
        present?: true,
        url: "/test/content_audio.mp3"
      )
    )

    content.define_singleton_method(:audio) do
      audio
    end

    render(AudioPlayButton::Component.new(content_record: content))
  end

  def sizes
    track = Track.new(
      id: 3,
      status: "completed"
    )

    track.define_singleton_method(:metadata_title) do
      "Size Test Track"
    end

    track.define_singleton_method(:audio) do
      OpenStruct.new(
        present?: true,
        url: "/test/audio.mp3"
      )
    end

    track.define_singleton_method(:content) do
      content = OpenStruct.new(
        id: 100,
        theme: "Test Theme"
      )

      # Mock tracks relation
      content.define_singleton_method(:tracks) do
        MockRelation.new([])
      end

      content
    end

    render_with_template(locals: { track: track })
  end
end
