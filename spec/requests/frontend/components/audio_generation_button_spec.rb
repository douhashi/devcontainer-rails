# frozen_string_literal: true

require "rails_helper"

RSpec.describe "audio_generation_button component", type: :request do
  describe "GET /rails/view_components/audio_generation_button/default" do
    it "shows generate button" do
      get "/rails/view_components/audio_generation_button/default"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("音源を生成")
    end
  end

  describe "GET /rails/view_components/audio_generation_button/completed" do
    it "shows delete button that is enabled" do
      get "/rails/view_components/audio_generation_button/completed"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("削除")
      expect(response.body).not_to include('disabled="disabled"')
    end
  end

  describe "GET /rails/view_components/audio_generation_button/processing" do
    it "shows processing button that is disabled" do
      get "/rails/view_components/audio_generation_button/processing"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("作成中")
      expect(response.body).to include('disabled')
    end
  end

  describe "GET /rails/view_components/audio_generation_button/failed" do
    it "shows delete button that is enabled" do
      get "/rails/view_components/audio_generation_button/failed"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("削除")
      expect(response.body).not_to include('disabled="disabled"')
    end
  end

  describe "GET /rails/view_components/audio_generation_button/pending" do
    it "shows pending button that is disabled" do
      get "/rails/view_components/audio_generation_button/pending"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("作成中")
      expect(response.body).to include('disabled')
    end
  end
end
