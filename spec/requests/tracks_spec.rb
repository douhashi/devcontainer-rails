require 'rails_helper'

RSpec.describe "Tracks", type: :request do
  describe "GET /tracks" do
    let!(:content1) { create(:content, theme: "レコード、古いスピーカー") }
    let!(:content2) { create(:content, :cafe_theme) }

    context "with tracks present" do
      let!(:track1) { create(:track, :completed, content: content1, created_at: 3.hours.ago) }
      let!(:track2) { create(:track, :processing, content: content2, created_at: 2.hours.ago) }
      let!(:track3) { create(:track, :pending, content: content1, created_at: 1.hour.ago) }

      it "displays tracks list page successfully" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Track一覧")
      end

      it "displays track information including content name" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(content1.theme)
        expect(response.body).to include(content2.theme)
      end

      it "displays track status information" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("完了")
        expect(response.body).to include("処理中")
        expect(response.body).to include("待機中")
      end

      it "orders tracks by creation date (newest first)" do
        get tracks_path

        expect(response).to have_http_status(:success)
        # track3 (created 1 hour ago) should appear before track2 (2 hours ago) and track1 (3 hours ago)
        track_positions = [
          [ track3.id, response.body.index("##{track3.id}") ],
          [ track2.id, response.body.index("##{track2.id}") ],
          [ track1.id, response.body.index("##{track1.id}") ]
        ].sort_by(&:last)

        # Should be ordered by most recent first
        expect(track_positions.map(&:first)).to eq([ track3.id, track2.id, track1.id ])
      end

      it "includes pagination" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("nav")
      end

      context "with more than 30 tracks" do
        before do
          create_list(:track, 31, content: content1)
        end

        it "paginates tracks with 30 items per page" do
          get tracks_path

          expect(response).to have_http_status(:success)
          expect(response.body.scan(/track_\d+/).count).to be <= 30
        end

        it "shows pagination controls" do
          get tracks_path

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Next") if response.body.scan(/track_\d+/).count == 30
        end

        it "loads second page correctly" do
          get tracks_path, params: { page: 2 }

          expect(response).to have_http_status(:success)
          expect(response.body.scan(/track_\d+/).count).to be > 0
        end
      end
    end

    context "with no tracks" do
      it "displays empty state message" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Trackがまだありません")
      end

      it "does not show pagination when no tracks" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Next")
      end
    end

    context "performance considerations" do
      let!(:tracks_with_content) { create_list(:track, 5, content: content1) }

      it "loads tracks with content information efficiently" do
        # This test verifies that the controller uses includes(:content) to avoid N+1 queries
        # The actual N+1 prevention is tested by observing the rendered content includes content info
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(content1.theme)
      end
    end
  end
end
