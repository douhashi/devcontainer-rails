require 'rails_helper'

RSpec.describe "Samples", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  describe "GET /sample" do
    it "returns http success" do
      get "/sample"
      expect(response).to have_http_status(:success)
    end
  end
end
