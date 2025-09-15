require 'rails_helper'
require 'vips'

RSpec.describe "Artworks::PreviewThumbnails", type: :request do
  let(:content) { create(:content) }
  let(:artwork) { create(:artwork, content: content) }

  describe "GET /contents/:content_id/artworks/preview_thumbnail" do
    context "when artwork exists with 1920x1080 image" do
      before do
        # Create a 1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_preview_image.jpg").to_s
        image = Vips::Image.black(1920, 1080, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Attach the image to artwork
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)
      end

      it "returns preview URLs for original and processed thumbnail" do
        get preview_thumbnail_content_artwork_path(content)

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("original_url")
        expect(json_response).to have_key("thumbnail_url")
        expect(json_response["original_url"]).to be_present
        expect(json_response["thumbnail_url"]).to be_present
      end

      it "generates temporary thumbnail without saving" do
        expect {
          get preview_thumbnail_content_artwork_path(content)
        }.not_to change { artwork.reload.image_derivatives }
      end
    end

    context "when artwork doesn't exist" do
      it "returns not found error" do
        content_without_artwork = create(:content)

        get preview_thumbnail_content_artwork_path(content_without_artwork)

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Artwork not found")
      end
    end

    context "when image is not eligible for YouTube thumbnail" do
      before do
        # Create a non-1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_preview_image_small.jpg").to_s
        image = Vips::Image.black(800, 600, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Attach the image to artwork
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)
      end

      it "returns unprocessable entity error" do
        get preview_thumbnail_content_artwork_path(content)

        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Image is not eligible for YouTube thumbnail (must be 1920x1080)")
      end
    end

    context "when thumbnail generation fails" do
      before do
        # Create a 1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_preview_image_error.jpg").to_s
        image = Vips::Image.black(1920, 1080, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Attach the image to artwork
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)

        # Mock ThumbnailGenerationService to raise an error
        allow_any_instance_of(ThumbnailGenerationService).to receive(:generate)
          .and_raise(ThumbnailGenerationService::GenerationError, "Test error")
      end

      it "returns internal server error" do
        get preview_thumbnail_content_artwork_path(content)

        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Failed to generate preview")
      end
    end
  end
end
