# frozen_string_literal: true

class Content::Form::Component < ApplicationViewComponent
  attr_reader :item, :form

  def initialize(item:, form:)
    @item = item
    @form = form
  end
end
