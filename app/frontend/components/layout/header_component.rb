class Layout::HeaderComponent < ApplicationViewComponent
  option :title
  option :show_menu_toggle, default: proc { true }
  option :current_user, optional: true

  private

  def truncated_email
    return nil unless current_user&.email

    email = current_user.email
    if email.length > 20
      "#{email[0..16]}..."
    else
      email
    end
  end

  def user_avatar_initial
    return "U" unless current_user&.email

    email = current_user.email
    return "U" if email.empty?

    email[0].upcase
  end

  def user_signed_in?
    current_user.present?
  end
end
