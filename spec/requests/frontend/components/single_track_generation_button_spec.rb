# frozen_string_literal: true

require "rails_helper"

RSpec.describe "single_track_generation_button component", type: :request do
  describe "GET /rails/view_components/single_track_generation_button/default" do
    it "shows generate button" do
      get "/rails/view_components/single_track_generation_button/default"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("音楽生成（2曲）")
    end
  end

  describe "GET /rails/view_components/single_track_generation_button/with_processing_track" do
    it "shows processing state" do
      get "/rails/view_components/single_track_generation_button/with_processing_track"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("生成中...")
      expect(response.body).to include("disabled")
      expect(response.body).to include("BGM生成処理中です")
    end
  end
end
