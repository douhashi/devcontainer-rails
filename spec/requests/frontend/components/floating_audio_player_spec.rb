# frozen_string_literal: true

require "rails_helper"

RSpec.describe "floating_audio_player component", type: :request do
  describe "GET /rails/view_components/floating_audio_player/default" do
    it "renders the component preview" do
      get "/rails/view_components/floating_audio_player/default"

      expect(response).to have_http_status(:success)
    end
  end
end
