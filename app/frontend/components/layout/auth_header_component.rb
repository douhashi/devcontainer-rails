# frozen_string_literal: true

module Layout
  class AuthHeaderComponent < ApplicationViewComponent
    def initialize(title: nil)
      @title = title || Settings.app.name
      super()
    end

    private

    attr_reader :title
  end
end
