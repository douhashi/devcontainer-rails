# frozen_string_literal: true

require "rails_helper"

RSpec.describe "artwork_thumbnail_status_badge component", type: :request do
  describe "GET /rails/view_components/artwork_thumbnail_status_badge/default" do
    it "renders the component preview" do
      get "/rails/view_components/artwork_thumbnail_status_badge/default"

      expect(response).to have_http_status(:success)
    end
  end
end
