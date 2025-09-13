# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Dropdown Unauthenticated", type: :request do
  describe "未ログイン状態での表示" do
    it "未ログイン時はログイン画面にリダイレクトされる" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(response.body).to include("ログイン")
    end
  end
end
