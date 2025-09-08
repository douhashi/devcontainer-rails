require "rails_helper"

RSpec.describe "Tracks search", type: :request do
  let!(:content1) { create(:content, theme: "Relaxing Music") }
  let!(:content2) { create(:content, theme: "Focus Sounds") }

  let!(:track1) do
    create(:track,
      content: content1,
      status: "completed",
      metadata: { music_title: "Morning Coffee" },
      created_at: 1.day.ago)
  end

  let!(:track2) do
    create(:track,
      content: content2,
      status: "pending",
      metadata: { music_title: "Deep Work" },
      created_at: 1.week.ago)
  end

  let!(:track3) do
    create(:track,
      content: content1,
      status: "processing",
      metadata: { music_title: "Evening Relaxation" },
      created_at: 2.hours.ago)
  end

  describe "GET /tracks" do
    it "returns all tracks when no search parameters" do
      get tracks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Morning Coffee")
      expect(response.body).to include("Deep Work")
      expect(response.body).to include("Evening Relaxation")
    end

    it "filters by content theme" do
      get tracks_path, params: { q: { content_theme_cont: "Relax" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Morning Coffee")
      expect(response.body).to include("Evening Relaxation")
      expect(response.body).not_to include("Deep Work")
    end

    it "filters by music title" do
      get tracks_path, params: { q: { music_title_cont: "Coffee" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Morning Coffee")
      expect(response.body).not_to include("Deep Work")
      expect(response.body).not_to include("Evening Relaxation")
    end

    it "filters by status" do
      get tracks_path, params: { q: { status_eq: "pending" } }
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Morning Coffee")
      expect(response.body).to include("Deep Work")
      expect(response.body).not_to include("Evening Relaxation")
    end

    it "filters by created_at range" do
      get tracks_path, params: {
        q: {
          created_at_gteq: 3.days.ago.to_date.to_s,
          created_at_lteq: Date.today.to_s
        }
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Morning Coffee")
      expect(response.body).not_to include("Deep Work")
      expect(response.body).to include("Evening Relaxation")
    end

    it "combines multiple search criteria" do
      get tracks_path, params: {
        q: {
          content_theme_cont: "Relax",
          status_eq: "completed"
        }
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Morning Coffee")
      expect(response.body).not_to include("Deep Work")
      expect(response.body).not_to include("Evening Relaxation")
    end

    it "preserves search parameters in URL" do
      get tracks_path, params: { q: { status_eq: "completed" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('name="q[status_eq]"')
    end

    it "handles pagination with search results" do
      # Create more tracks
      10.times do
        create(:track, content: content1, status: "completed")
      end

      get tracks_path, params: { q: { status_eq: "completed" }, page: 2 }
      expect(response).to have_http_status(:success)
    end
  end
end
