# frozen_string_literal: true

class Icon::Preview < ApplicationViewComponentPreview
  # @label Default
  def default
    render(Icon::Component.new(name: :music))
  end

  # @!group Basic Icons

  # @label Image
  def image
    render(Icon::Component.new(name: :image))
  end

  # @label Music
  def music
    render(Icon::Component.new(name: :music))
  end

  # @label Video
  def video
    render(Icon::Component.new(name: :video))
  end

  # @label Delete
  def delete
    render(Icon::Component.new(name: :delete))
  end

  # @label Spinner
  def spinner
    render(Icon::Component.new(name: :spinner))
  end

  # @label Play
  def play
    render(Icon::Component.new(name: :play))
  end

  # @label Pause
  def pause
    render(Icon::Component.new(name: :pause))
  end

  # @label Check
  def check
    render(Icon::Component.new(name: :check))
  end

  # @!endgroup

  # @!group Size Variations

  # @label Small Icons
  def small_icons
    render_with_template(locals: {
      icons: %i[image music video delete play pause check].map do |name|
        Icon::Component.new(name: name, size: :sm)
      end
    })
  end

  # @label Medium Icons (Default)
  def medium_icons
    render_with_template(locals: {
      icons: %i[image music video delete play pause check].map do |name|
        Icon::Component.new(name: name, size: :md)
      end
    })
  end

  # @label Large Icons
  def large_icons
    render_with_template(locals: {
      icons: %i[image music video delete play pause check].map do |name|
        Icon::Component.new(name: name, size: :lg)
      end
    })
  end

  # @!endgroup

  # @!group Color Variations

  # @label Colored Icons
  def colored_icons
    render_with_template(locals: {
      icons: [
        Icon::Component.new(name: :music, color: "text-blue-500"),
        Icon::Component.new(name: :video, color: "text-green-500"),
        Icon::Component.new(name: :image, color: "text-purple-500"),
        Icon::Component.new(name: :delete, color: "text-red-500"),
        Icon::Component.new(name: :check, color: "text-green-600")
      ]
    })
  end

  # @!endgroup

  # @!group Accessibility

  # @label With Aria Labels
  def with_aria_labels
    render_with_template(locals: {
      icons: [
        Icon::Component.new(name: :music, aria_label: "Music file"),
        Icon::Component.new(name: :video, aria_label: "Video file"),
        Icon::Component.new(name: :image, aria_label: "Image file"),
        Icon::Component.new(name: :delete, aria_label: "Delete item")
      ]
    })
  end

  # @!endgroup

  # @!group All Icons Catalog

  # @label Icon Catalog
  def catalog
    render_with_template(locals: {
      icon_names: Icon::Component::ICONS.keys,
      sizes: Icon::Component::SIZES.keys
    })
  end

  # @!endgroup

  # @!group Animation

  # @label Animated Spinner
  def animated_spinner
    render_with_template(locals: {
      spinner: Icon::Component.new(name: :spinner, aria_label: "Loading")
    })
  end

  # @!endgroup
end
