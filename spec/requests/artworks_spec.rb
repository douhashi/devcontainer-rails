require 'rails_helper'

RSpec.describe "Artworks", type: :request do
  let(:user) { create(:user) }
  let(:content) { create(:content) }
  let(:valid_attributes) { { artwork: { image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg') } } }
  let(:invalid_attributes) { { artwork: { image: nil } } }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  describe "POST /contents/:content_id/artworks" do
    context "with valid parameters" do
      it "creates artwork and responds with correct format (HTML/Turbo Stream)" do
        # HTML format
        expect {
          post content_artworks_path(content), params: valid_attributes
        }.to change(Artwork, :count).by(1)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークが正常にアップロードされました")

        # Turbo Stream format - use new content to avoid conflicts
        content2 = create(:content)
        expect {
          post content_artworks_path(content2),
               params: valid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Artwork, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "with invalid parameters" do
      it "rejects invalid data and responds with correct error format (HTML/Turbo Stream)" do
        # HTML format
        expect {
          post content_artworks_path(content), params: invalid_attributes
        }.not_to change(Artwork, :count)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークのアップロードに失敗しました")

        # Turbo Stream format - use new content to avoid conflicts
        content2 = create(:content)
        expect {
          post content_artworks_path(content2),
               params: invalid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(Artwork, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /contents/:content_id/artworks/:id" do
    let!(:artwork) { create(:artwork, content: content) }
    let(:new_image) { fixture_file_upload('images/sd_placeholder.jpg', 'image/jpeg') }
    let(:update_attributes) { { artwork: { image: new_image } } }

    it "updates artwork and responds with correct format (HTML/Turbo Stream)" do
      # HTML format
      patch content_artwork_path(content, artwork), params: update_attributes
      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include("アートワークが正常に更新されました")

      # Turbo Stream format
      patch content_artwork_path(content, artwork),
            params: update_attributes,
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream')
    end
  end

  describe "DELETE /contents/:content_id/artworks/:id" do
    let!(:artwork) { create(:artwork, content: content) }

    it "destroys artwork and responds with correct format (HTML/Turbo Stream)" do
      # HTML format
      expect {
        delete content_artwork_path(content, artwork)
      }.to change(Artwork, :count).by(-1)
      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include("アートワークが削除されました")

      # Turbo Stream format
      new_artwork = create(:artwork, content: content)
      expect {
        delete content_artwork_path(content, new_artwork),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Artwork, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream')
    end
  end
end
