class Layout::FooterComponent < ApplicationViewComponent
  private

  def app_version
    Settings.app.version rescue "1.0.0"
  end

  def current_year
    Date.current.year
  end
end
