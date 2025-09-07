# frozen_string_literal: true

class SampleButton::Preview < ApplicationViewComponentPreview
  # You can specify the container class for the default template
  # self.container_class = "w-1/2 border border-gray-300"

  # @param url text
  # @param text text
  def default(url: "#", text: "Click me")
    render(SampleButton::Component.new(url: url, text: text))
  end
end
