# frozen_string_literal: true

require "rails_helper"

RSpec.describe "music_generation_status_summary component", type: :request do
  describe "GET /rails/view_components/music_generation_status_summary/default" do
    it "renders the component preview" do
      get "/rails/view_components/music_generation_status_summary/default"

      expect(response).to have_http_status(:success)
    end
  end
end
