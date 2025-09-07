class Layout::HeaderComponentPreview < ApplicationViewComponentPreview
  # @label Default header
  def default
    render Layout::HeaderComponent.new(title: "Lofi BGM System")
  end

  # @label With menu toggle disabled
  def no_menu_toggle
    render Layout::HeaderComponent.new(title: "Lofi BGM System", show_menu_toggle: false)
  end

  # @label Long title
  def long_title
    render Layout::HeaderComponent.new(title: "Very Long Application Title That Tests Header Layout")
  end

  # @label Custom styling context
  def with_background
    "<div class='bg-gray-900 p-4'>
      #{render Layout::HeaderComponent.new(title: 'Header with Background')}
    </div>".html_safe
  end
end
