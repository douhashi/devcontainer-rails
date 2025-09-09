# frozen_string_literal: true

class Contents::Show::Component < ApplicationViewComponent
  attr_reader :item

  def initialize(item:)
    @item = item
  end

  private

  def formatted_date(date)
    return "" unless date
    date.strftime("%Y年%m月%d日 %H:%M")
  end

  def completion_status
    item.completion_status
  end
end
