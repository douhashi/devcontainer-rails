# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Dropdown Unauthenticated", type: :system do
  describe "未ログイン状態での表示" do
    it "未ログイン時はログイン画面にリダイレクトされる" do
      visit root_path
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_text("ログイン")
    end
  end
end
