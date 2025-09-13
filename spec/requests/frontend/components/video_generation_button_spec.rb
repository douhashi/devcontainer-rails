# frozen_string_literal: true

require "rails_helper"

RSpec.describe "video_generation_button component", type: :request do
  describe "GET /rails/view_components/video_generation_button/default" do
    it "shows video generation button" do
      get "/rails/view_components/video_generation_button/default"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("動画を生成")
    end
  end

  describe "GET /rails/view_components/video_generation_button/completed" do
    it "shows download link and delete button" do
      get "/rails/view_components/video_generation_button/completed"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("ダウンロード")
      expect(response.body).to include("削除")
    end
  end

  describe "GET /rails/view_components/video_generation_button/processing" do
    it "shows processing button that is disabled" do
      get "/rails/view_components/video_generation_button/processing"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("作成中")
      expect(response.body).to include("disabled")
    end
  end

  describe "GET /rails/view_components/video_generation_button/failed" do
    it "shows failed message and delete button" do
      get "/rails/view_components/video_generation_button/failed"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("生成失敗")
      expect(response.body).to include("削除")
    end
  end
end
