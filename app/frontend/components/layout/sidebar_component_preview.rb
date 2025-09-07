class Layout::SidebarComponentPreview < ApplicationViewComponentPreview
  # @label Default navigation
  def default
    navigation_items = [
      { name: "Content", path: "/content", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" },
      { name: "Artwork", path: "/artwork", icon: "photo" }
    ]

    render Layout::SidebarComponent.new(
      navigation_items: navigation_items,
      current_path: "/content"
    )
  end

  # @label Extended navigation
  def extended_navigation
    navigation_items = [
      { name: "Dashboard", path: "/dashboard", icon: "home" },
      { name: "Content", path: "/content", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" },
      { name: "Artwork", path: "/artwork", icon: "photo" },
      { name: "Analytics", path: "/analytics", icon: "chart-bar" },
      { name: "Settings", path: "/settings", icon: "cog" }
    ]

    render Layout::SidebarComponent.new(
      navigation_items: navigation_items,
      current_path: "/tracks"
    )
  end

  # @label No active item
  def no_active_item
    navigation_items = [
      { name: "Content", path: "/content", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" },
      { name: "Artwork", path: "/artwork", icon: "photo" }
    ]

    render Layout::SidebarComponent.new(
      navigation_items: navigation_items,
      current_path: "/other-path"
    )
  end

  # @label With background context
  def with_background
    navigation_items = [
      { name: "Content", path: "/content", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" },
      { name: "Artwork", path: "/artwork", icon: "photo" }
    ]

    "<div class='bg-gray-900 p-4' style='height: 600px;'>
      #{render Layout::SidebarComponent.new(navigation_items: navigation_items, current_path: '/content')}
    </div>".html_safe
  end
end
