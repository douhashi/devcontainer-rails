class Card::ComponentPreview < ApplicationViewComponentPreview
  # @label Default card
  def default
    render Card::Component.new do
      "This is a basic card with default styling."
    end
  end

  # @label Card with title
  def with_title
    render Card::Component.new(title: "Card Title") do
      "This card has a title in the header section."
    end
  end

  # @label Bordered variant
  def bordered
    render Card::Component.new(title: "Bordered Card", variant: :bordered) do
      "This card uses the bordered variant with a visible border."
    end
  end

  # @label Elevated variant
  def elevated
    render Card::Component.new(title: "Elevated Card", variant: :elevated) do
      "This card uses the elevated variant with a shadow effect."
    end
  end

  # @label Small padding
  def small_padding
    render Card::Component.new(title: "Small Padding", padding: :sm) do
      "This card uses small padding (p-4)."
    end
  end

  # @label Large padding
  def large_padding
    render Card::Component.new(title: "Large Padding", padding: :lg) do
      "This card uses large padding (p-8)."
    end
  end

  # @label With header slot
  def with_header_slot
    render Card::Component.new do |component|
      component.with_header do
        "<div class='flex items-center space-x-2'>
          <svg class='w-5 h-5 text-blue-400' fill='currentColor' viewBox='0 0 20 20'>
            <path d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'/>
          </svg>
          <span class='text-lg font-medium text-gray-100'>Custom Header</span>
        </div>".html_safe
      end
      "This card uses a custom header slot with an icon."
    end
  end

  # @label With footer slot
  def with_footer_slot
    render Card::Component.new(title: "Card with Footer") do |component|
      component.with_footer do
        "<div class='flex justify-between items-center text-sm text-gray-400'>
          <span>Last updated: 2 hours ago</span>
          <button class='text-blue-400 hover:text-blue-300'>Edit</button>
        </div>".html_safe
      end
      "This card has a footer section with metadata and actions."
    end
  end

  # @label With actions slot
  def with_actions_slot
    render Card::Component.new(title: "Card with Actions") do |component|
      component.with_actions do
        "<div class='flex space-x-2'>
          <button class='px-3 py-1.5 text-sm bg-blue-600 text-white rounded hover:bg-blue-700'>
            Edit
          </button>
          <button class='px-3 py-1.5 text-sm bg-red-600 text-white rounded hover:bg-red-700'>
            Delete
          </button>
        </div>".html_safe
      end
      "This card has action buttons in the top-right corner."
    end
  end

  # @label Complex card with all slots
  def complex_example
    render Card::Component.new(title: "Music Generation Request", variant: :elevated, padding: :lg) do |component|
      component.with_actions do
        "<button class='px-3 py-1.5 text-sm bg-red-600 text-white rounded hover:bg-red-700 flex items-center'>
          <svg class='w-4 h-4 mr-1' fill='currentColor' viewBox='0 0 20 20'>
            <path fill-rule='evenodd' d='M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9z' clip-rule='evenodd'/>
          </svg>
          Delete
        </button>".html_safe
      end

      component.with_footer do
        "<div class='flex justify-between items-center text-sm text-gray-400'>
          <span>Created: Jan 15, 2024</span>
          <div class='flex items-center space-x-2'>
            <span class='px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs'>Completed</span>
          </div>
        </div>".html_safe
      end

      "<div class='space-y-4'>
        <div class='bg-gray-900 rounded-lg p-4'>
          <h4 class='text-lg font-medium text-gray-200 mb-2'>Audio Prompt</h4>
          <p class='text-gray-300'>Chill lofi hip hop with jazz influences, perfect for studying</p>
        </div>
        <div class='grid grid-cols-2 gap-4 text-sm'>
          <div>
            <span class='text-gray-400'>Duration:</span>
            <span class='text-gray-200 ml-2'>3 minutes</span>
          </div>
          <div>
            <span class='text-gray-400'>Status:</span>
            <span class='text-green-400 ml-2'>Ready</span>
          </div>
        </div>
      </div>".html_safe
    end
  end

  # @label Custom class example
  def with_custom_class
    render Card::Component.new(
      title: "Custom Styled Card",
      class: "border-l-4 border-blue-500"
    ) do
      "This card has a custom class applied for additional styling."
    end
  end
end
