require "rails_helper"

RSpec.describe "Artworks Download", type: :request do
  let(:content) { create(:content) }
  let!(:artwork) { create(:artwork, content: content) }

  describe "GET /contents/:content_id/artworks/:id/download/:variation" do
    context "when downloading original variation" do
      it "returns the file with correct filename" do
        get download_content_artwork_path(content, artwork, variation: "original")

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("content_0001_original")
        expect(response.headers["Content-Type"]).to match(/image/)
      end

      context "with content id 99" do
        let(:content) { create(:content, id: 99) }

        it "formats the content id with zero padding" do
          get download_content_artwork_path(content, artwork, variation: "original")

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Disposition"]).to include("content_0099_original")
        end
      end

      context "with content id 9999" do
        let(:content) { create(:content, id: 9999) }

        it "formats the content id with zero padding" do
          get download_content_artwork_path(content, artwork, variation: "original")

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Disposition"]).to include("content_9999_original")
        end
      end
    end

    context "when downloading youtube_thumbnail variation" do
      let(:content_with_thumbnail) { create(:content) }
      let!(:artwork_with_thumbnail) { create(:artwork, :with_youtube_thumbnail, content: content_with_thumbnail) }

      it "returns the file with correct filename" do
        get download_content_artwork_path(content_with_thumbnail, artwork_with_thumbnail, variation: "youtube_thumbnail")

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("content_#{content_with_thumbnail.id.to_s.rjust(4, '0')}_youtube.jpg")
      end
    end

    context "when artwork does not exist" do
      let(:content_without_artwork) { create(:content) }

      it "returns 404" do
        get download_content_artwork_path(content_without_artwork, 999999, variation: "original")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when variation does not exist" do
      it "returns 404 for non-existent variation" do
        get download_content_artwork_path(content, artwork, variation: "invalid_variation")

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for youtube_thumbnail when not generated" do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)

        get download_content_artwork_path(content, artwork, variation: "youtube_thumbnail")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when variation parameter is missing" do
      it "returns 404 for route not found" do
        get "/contents/#{content.id}/artworks/#{artwork.id}/download"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
