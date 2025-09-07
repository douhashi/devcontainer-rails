class Layout::HeaderComponent < ApplicationViewComponent
  option :title
  option :show_menu_toggle, default: proc { true }
end
