# frozen_string_literal: true

require "rails_helper"

RSpec.describe "audio_play_button component", type: :request do
  describe "GET /rails/view_components/audio_play_button/default" do
    it "renders the component preview" do
      get "/rails/view_components/audio_play_button/default"

      expect(response).to have_http_status(:success)
    end
  end
end
