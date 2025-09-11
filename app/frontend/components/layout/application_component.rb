class Layout::ApplicationComponent < ApplicationViewComponent
  option :title, default: proc { Settings.app.name }

  private

  def navigation_items
    [
      { name: "Content", path: "/contents", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" }
    ]
  end

  def current_path
    helpers.request.path
  end

  def show_menu_toggle?
    true
  end

  def current_user
    helpers.current_user if helpers.respond_to?(:current_user)
  end
end
