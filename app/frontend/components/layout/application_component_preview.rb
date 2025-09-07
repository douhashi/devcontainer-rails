class Layout::ApplicationComponentPreview < ApplicationViewComponentPreview
  # @label Default layout
  def default
    render Layout::ApplicationComponent.new(title: "Lofi BGM System") do
      "<div class='space-y-6'>
        <h1 class='text-3xl font-bold text-gray-100'>Welcome to Lofi BGM System</h1>
        <p class='text-gray-300'>This is the main content area within the dark theme 2-column layout.</p>
        <div class='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'>
          <div class='bg-gray-800 p-4 rounded-lg border border-gray-700'>
            <h3 class='font-semibold text-gray-100 mb-2'>Content Management</h3>
            <p class='text-gray-400 text-sm'>Manage your content creation workflow with powerful tools.</p>
          </div>
          <div class='bg-gray-800 p-4 rounded-lg border border-gray-700'>
            <h3 class='font-semibold text-gray-100 mb-2'>Track Production</h3>
            <p class='text-gray-400 text-sm'>Create and edit music tracks for your lofi BGM collection.</p>
          </div>
          <div class='bg-gray-800 p-4 rounded-lg border border-gray-700'>
            <h3 class='font-semibold text-gray-100 mb-2'>Artwork Gallery</h3>
            <p class='text-gray-400 text-sm'>Organize and manage visual assets for your content.</p>
          </div>
        </div>
      </div>".html_safe
    end
  end

  # @label With custom title
  def custom_title
    render Layout::ApplicationComponent.new(title: "Custom Application Title") do
      "<div class='text-center py-12'>
        <h1 class='text-4xl font-bold text-gray-100 mb-4'>Custom Title Demo</h1>
        <p class='text-gray-300'>This demonstrates the layout with a custom application title.</p>
      </div>".html_safe
    end
  end

  # @label Long content (scrollable)
  def long_content
    render Layout::ApplicationComponent.new(title: "Scrollable Content") do
      content = (1..50).map { |i|
        "<div class='bg-gray-800 p-4 rounded-lg border border-gray-700 mb-4'>
          <h3 class='font-semibold text-gray-100'>Content Block #{i}</h3>
          <p class='text-gray-400 text-sm'>This is content block number #{i}. It demonstrates how the layout handles long, scrollable content within the main content area.</p>
        </div>"
      }.join("\n")

      "<div class='space-y-4'>#{content}</div>".html_safe
    end
  end
end
