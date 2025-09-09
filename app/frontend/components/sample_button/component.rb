# frozen_string_literal: true

# Legacy wrapper for SampleButton using the new Button::Component
class SampleButton::Component < ApplicationViewComponent
  with_collection_parameter :sample_button

  option :url
  option :text

  def call
    render(Button::Component.new(
      text: text,
      href: url,
      variant: :primary
    ))
  end
end
