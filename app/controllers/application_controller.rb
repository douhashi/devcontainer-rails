class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :skip_authentication?
  layout :determine_layout

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def determine_layout
    devise_controller? ? "auth" : "application"
  end

  def skip_authentication?
    # Skip authentication for Lookbook and ViewComponent previews in development
    (request.path.start_with?("/dev/lookbook") || request.path.start_with?("/rails/view_components")) && Rails.env.development?
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
