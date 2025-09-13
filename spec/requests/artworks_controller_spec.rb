require "rails_helper"
require "vips"

RSpec.describe ArtworksController, type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:content) { create(:content) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  describe "POST /contents/:content_id/artworks" do
    context "with valid artwork data" do
      let(:artwork_params) { { artwork: { image: fixture_file_upload("test_fhd_artwork.jpg", "image/jpeg") } } }

      before do
        # Create a mock FHD image for testing
        create_test_fhd_image(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))
      end

      after do
        # Clean up test file
        FileUtils.rm_f(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))
      end

      it "creates artwork and schedules thumbnail generation" do
        expect {
          post content_artworks_path(content), params: artwork_params
        }.to change { content.reload.artwork.present? }.from(false).to(true)

        expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークが正常にアップロードされました")
      end

      context "when request is via Turbo Stream" do
        let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

        it "returns turbo stream response" do
          post content_artworks_path(content), params: artwork_params, headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("turbo-stream")
        end

        it "schedules thumbnail generation for eligible artwork" do
          post content_artworks_path(content), params: artwork_params, headers: headers
          expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
        end
      end
    end

    context "with non-eligible artwork (not 1920x1080)" do
      let(:artwork_params) { { artwork: { image: fixture_file_upload("test_small_artwork.jpg", "image/jpeg") } } }

      before do
        # Create a mock small image for testing
        create_test_image_with_size(Rails.root.join("spec/fixtures/files/test_small_artwork.jpg"), 800, 600)
      end

      after do
        FileUtils.rm_f(Rails.root.join("spec/fixtures/files/test_small_artwork.jpg"))
      end

      it "creates artwork but does not schedule thumbnail generation" do
        expect {
          post content_artworks_path(content), params: artwork_params
        }.to change { content.reload.artwork.present? }.from(false).to(true)

        expect(DerivativeProcessingJob).not_to have_been_enqueued

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークが正常にアップロードされました")
      end
    end

    context "with invalid artwork data" do
      let(:artwork_params) { { artwork: { image: nil } } }

      it "does not create artwork and returns error" do
        expect {
          post content_artworks_path(content), params: artwork_params
        }.not_to change { content.reload.artwork.present? }

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークのアップロードに失敗しました")
      end

      context "when request is via Turbo Stream" do
        let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

        it "returns turbo stream error response" do
          post content_artworks_path(content), params: artwork_params, headers: headers

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("turbo-stream")
        end
      end
    end
  end

  describe "PATCH /contents/:content_id/artworks/:id" do
    let(:artwork) { create(:artwork, content: content) }
    let(:artwork_params) { { artwork: { image: fixture_file_upload("test_fhd_artwork.jpg", "image/jpeg") } } }

    before do
      create_test_fhd_image(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))
    end

    after do
      FileUtils.rm_f(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))
    end

    it "updates artwork and schedules thumbnail generation" do
      patch content_artwork_path(content, artwork), params: artwork_params
      expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)

      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include("アートワークが正常に更新されました")
    end
  end

  describe "DELETE /contents/:content_id/artworks/:id" do
    let!(:artwork) { create(:artwork, content: content) }

    it "deletes artwork" do
      expect {
        delete content_artwork_path(content, artwork)
      }.to change { content.reload.artwork.present? }.from(true).to(false)

      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include("アートワークが削除されました")
    end

    context "when request is via Turbo Stream" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      it "returns turbo stream response" do
        delete content_artwork_path(content, artwork), headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "POST /contents/:content_id/artworks/:id/regenerate_thumbnail" do
    let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed, thumbnail_generation_error: "Previous error") }

    before do
      create_test_fhd_image(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))

      # Mock the image to be eligible
      allow_any_instance_of(Artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
    end

    after do
      FileUtils.rm_f(Rails.root.join("spec/fixtures/files/test_fhd_artwork.jpg"))
    end

    it "regenerates thumbnail for failed artwork" do
      expect {
        post regenerate_thumbnail_content_artwork_path(content, artwork)
      }.to change { artwork.reload.thumbnail_generation_status }.from("failed").to("pending")

      expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include("YouTube用サムネイルの再生成を開始しました")
    end

    context "when artwork is already processing" do
      before do
        clear_enqueued_jobs
        artwork.update!(thumbnail_generation_status: :processing)
      end

      it "does not regenerate and returns info message" do
        expect {
          post regenerate_thumbnail_content_artwork_path(content, artwork)
        }.not_to change { enqueued_jobs.size }

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("サムネイル生成は既に実行中です")
      end
    end

    context "when artwork is not eligible" do
      before do
        allow_any_instance_of(Artwork).to receive(:youtube_thumbnail_eligible?).and_return(false)
      end

      it "does not regenerate and returns error message" do
        post regenerate_thumbnail_content_artwork_path(content, artwork)

        expect(DerivativeProcessingJob).not_to have_been_enqueued
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube用サムネイル生成の対象外です")
      end
    end

    context "when request is via Turbo Stream" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      it "returns turbo stream response" do
        post regenerate_thumbnail_content_artwork_path(content, artwork), headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end

      it "schedules thumbnail regeneration" do
        post regenerate_thumbnail_content_artwork_path(content, artwork), headers: headers

        expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
        expect(artwork.reload.thumbnail_generation_status).to eq("pending")
        expect(artwork.thumbnail_generation_error).to be_nil
      end
    end
  end

  private

  def create_test_fhd_image(path)
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(path))

    # Create a simple 1920x1080 JPEG image for testing
    image = Vips::Image.black(1920, 1080, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path.to_s, Q: 90)
  end

  def create_test_image_with_size(path, width, height)
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(path))

    image = Vips::Image.black(width, height, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path.to_s, Q: 90)
  end
end
