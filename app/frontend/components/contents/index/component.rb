# frozen_string_literal: true

class Contents::Index::Component < ApplicationViewComponent
  attr_reader :contents

  def initialize(contents:)
    @contents = contents
  end

  private

  def empty_state?
    contents.empty?
  end

  def paginated?
    contents.respond_to?(:current_page)
  end
end
