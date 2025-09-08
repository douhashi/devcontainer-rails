require 'rails_helper'

RSpec.describe "Artworks", type: :request do
  let(:content) { create(:content) }
  let(:valid_attributes) { { artwork: { image: fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg') } } }
  let(:invalid_attributes) { { artwork: { image: nil } } }

  describe "POST /contents/:content_id/artworks" do
    context "with valid parameters" do
      context "when requesting HTML format" do
        it "creates a new Artwork and redirects" do
          expect {
            post content_artworks_path(content), params: valid_attributes
          }.to change(Artwork, :count).by(1)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("アートワークが正常にアップロードされました")
        end
      end

      context "when requesting Turbo Stream format" do
        it "creates a new Artwork and returns Turbo Stream" do
          expect {
            post content_artworks_path(content),
                 params: valid_attributes,
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change(Artwork, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include('turbo-stream')
          expect(response.body).to include("artwork_#{content.id}")
        end
      end
    end

    context "with invalid parameters" do
      context "when requesting HTML format" do
        it "does not create a new Artwork and redirects with error" do
          expect {
            post content_artworks_path(content), params: invalid_attributes
          }.not_to change(Artwork, :count)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("アートワークのアップロードに失敗しました")
        end
      end

      context "when requesting Turbo Stream format" do
        it "does not create a new Artwork and returns error Turbo Stream" do
          expect {
            post content_artworks_path(content),
                 params: invalid_attributes,
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.not_to change(Artwork, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include('turbo-stream')
        end
      end
    end
  end

  describe "PATCH /contents/:content_id/artworks/:id" do
    let!(:artwork) { create(:artwork, content: content) }
    let(:new_image) { fixture_file_upload('spec/fixtures/new_test_image.jpg', 'image/jpeg') }
    let(:update_attributes) { { artwork: { image: new_image } } }

    context "with valid parameters" do
      context "when requesting HTML format" do
        it "updates the Artwork and redirects" do
          patch content_artwork_path(content, artwork), params: update_attributes

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("アートワークが正常に更新されました")
        end
      end

      context "when requesting Turbo Stream format" do
        it "updates the Artwork and returns Turbo Stream" do
          patch content_artwork_path(content, artwork),
                params: update_attributes,
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include('turbo-stream')
          expect(response.body).to include("artwork_#{content.id}")
        end
      end
    end
  end

  describe "DELETE /contents/:content_id/artworks/:id" do
    let!(:artwork) { create(:artwork, content: content) }

    context "when requesting HTML format" do
      it "destroys the Artwork and redirects" do
        expect {
          delete content_artwork_path(content, artwork)
        }.to change(Artwork, :count).by(-1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークが削除されました")
      end
    end

    context "when requesting Turbo Stream format" do
      it "destroys the Artwork and returns Turbo Stream" do
        expect {
          delete content_artwork_path(content, artwork),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Artwork, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
        expect(response.body).to include("artwork_#{content.id}")
      end
    end
  end
end
