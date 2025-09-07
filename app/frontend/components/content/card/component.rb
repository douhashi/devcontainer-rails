# frozen_string_literal: true

class Content::Card::Component < ApplicationViewComponent
  attr_reader :item

  def initialize(item:)
    @item = item
  end
end
