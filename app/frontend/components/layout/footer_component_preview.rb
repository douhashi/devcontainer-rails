class Layout::FooterComponentPreview < ApplicationViewComponentPreview
  # @label Default footer
  def default
    render Layout::FooterComponent.new
  end

  # @label With background context
  def with_background
    "<div class='bg-gray-900 p-4'>
      #{render Layout::FooterComponent.new}
    </div>".html_safe
  end
end
