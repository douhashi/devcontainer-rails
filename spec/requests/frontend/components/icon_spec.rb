# frozen_string_literal: true

require "rails_helper"

RSpec.describe "icon component", type: :request do
  describe "GET /rails/view_components/icon/default" do
    it "renders the component preview" do
      get "/rails/view_components/icon/default"

      expect(response).to have_http_status(:success)
    end
  end
end
