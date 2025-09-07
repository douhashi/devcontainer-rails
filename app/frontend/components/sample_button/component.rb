# frozen_string_literal: true

class SampleButton::Component < ApplicationViewComponent
  with_collection_parameter :sample_button

  option :url
  option :text
end
