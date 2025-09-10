# frozen_string_literal: true

class AudioGenerationButton::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  # self.container_class = "w-1/2 border border-gray-300"

  def default
    content = Content.new(id: 1, theme: "Test Content")
    # Mock tracks to satisfy prerequisites
    content.define_singleton_method(:tracks) do
      tracks_relation = []
      tracks_relation.define_singleton_method(:completed) do
        completed_tracks = [
          Track.new(id: 1, content: content, status: :completed, duration_sec: 180),
          Track.new(id: 2, content: content, status: :completed, duration_sec: 200)
        ]
        completed_tracks.define_singleton_method(:exists?) { true }
        completed_tracks.define_singleton_method(:where) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:not) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:count) { 2 }
        completed_tracks
      end
      tracks_relation
    end
    # Mock artwork
    content.define_singleton_method(:artwork) do
      artwork = Object.new
      artwork.define_singleton_method(:present?) { true }
      artwork
    end
    content.define_singleton_method(:audio) { nil }
    render AudioGenerationButton::Component.new(content_record: content)
  end

  def completed
    content = Content.new(id: 1, theme: "Test Content")
    audio = Audio.new(id: 1, content: content, status: :completed, created_at: 1.hour.ago)
    audio.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:audio) { audio }
    # Mock tracks
    content.define_singleton_method(:tracks) do
      tracks_relation = []
      tracks_relation.define_singleton_method(:completed) do
        completed_tracks = [
          Track.new(id: 1, content: content, status: :completed, duration_sec: 180),
          Track.new(id: 2, content: content, status: :completed, duration_sec: 200)
        ]
        completed_tracks.define_singleton_method(:exists?) { true }
        completed_tracks.define_singleton_method(:where) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:not) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:count) { 2 }
        completed_tracks
      end
      tracks_relation
    end
    # Mock artwork
    content.define_singleton_method(:artwork) do
      artwork = Object.new
      artwork.define_singleton_method(:present?) { true }
      artwork
    end
    render AudioGenerationButton::Component.new(content_record: content)
  end

  def processing
    content = Content.new(id: 1, theme: "Test Content")
    audio = Audio.new(id: 1, content: content, status: :processing, created_at: 30.minutes.ago)
    audio.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:audio) { audio }
    # Mock tracks
    content.define_singleton_method(:tracks) do
      tracks_relation = []
      tracks_relation.define_singleton_method(:completed) do
        completed_tracks = [
          Track.new(id: 1, content: content, status: :completed, duration_sec: 180),
          Track.new(id: 2, content: content, status: :completed, duration_sec: 200)
        ]
        completed_tracks.define_singleton_method(:exists?) { true }
        completed_tracks.define_singleton_method(:where) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:not) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:count) { 2 }
        completed_tracks
      end
      tracks_relation
    end
    # Mock artwork
    content.define_singleton_method(:artwork) do
      artwork = Object.new
      artwork.define_singleton_method(:present?) { true }
      artwork
    end
    render AudioGenerationButton::Component.new(content_record: content)
  end

  def failed
    content = Content.new(id: 1, theme: "Test Content")
    audio = Audio.new(id: 1, content: content, status: :failed, created_at: 2.hours.ago)
    audio.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:audio) { audio }
    # Mock tracks
    content.define_singleton_method(:tracks) do
      tracks_relation = []
      tracks_relation.define_singleton_method(:completed) do
        completed_tracks = [
          Track.new(id: 1, content: content, status: :completed, duration_sec: 180),
          Track.new(id: 2, content: content, status: :completed, duration_sec: 200)
        ]
        completed_tracks.define_singleton_method(:exists?) { true }
        completed_tracks.define_singleton_method(:where) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:not) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:count) { 2 }
        completed_tracks
      end
      tracks_relation
    end
    # Mock artwork
    content.define_singleton_method(:artwork) do
      artwork = Object.new
      artwork.define_singleton_method(:present?) { true }
      artwork
    end
    render AudioGenerationButton::Component.new(content_record: content)
  end

  def pending
    content = Content.new(id: 1, theme: "Test Content")
    audio = Audio.new(id: 1, content: content, status: :pending, created_at: 10.minutes.ago)
    audio.define_singleton_method(:persisted?) { true }
    content.define_singleton_method(:audio) { audio }
    # Mock tracks
    content.define_singleton_method(:tracks) do
      tracks_relation = []
      tracks_relation.define_singleton_method(:completed) do
        completed_tracks = [
          Track.new(id: 1, content: content, status: :completed, duration_sec: 180),
          Track.new(id: 2, content: content, status: :completed, duration_sec: 200)
        ]
        completed_tracks.define_singleton_method(:exists?) { true }
        completed_tracks.define_singleton_method(:where) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:not) do |*args|
          self
        end
        completed_tracks.define_singleton_method(:count) { 2 }
        completed_tracks
      end
      tracks_relation
    end
    # Mock artwork
    content.define_singleton_method(:artwork) do
      artwork = Object.new
      artwork.define_singleton_method(:present?) { true }
      artwork
    end
    render AudioGenerationButton::Component.new(content_record: content)
  end
end
