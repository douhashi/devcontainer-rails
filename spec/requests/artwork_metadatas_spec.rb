require 'rails_helper'

RSpec.describe "ArtworkMetadata", type: :request do
  let(:content) { create(:content) }
  let(:valid_attributes) do
    {
      artwork_metadata: {
        positive_prompt: "beautiful landscape, digital art, vibrant colors",
        negative_prompt: "blurry, low quality, distorted"
      }
    }
  end
  let(:invalid_attributes) do
    {
      artwork_metadata: {
        positive_prompt: "",
        negative_prompt: ""
      }
    }
  end

  before do
    I18n.locale = :ja
  end

  describe "POST /contents/:content_id/artwork_metadata" do
    context "with valid parameters" do
      it "creates artwork_metadata and redirects to content" do
        expect {
          post content_artwork_metadata_path(content), params: valid_attributes
        }.to change(ArtworkMetadata, :count).by(1)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークメタデータが作成されました")
      end

      it "creates artwork_metadata via Turbo Stream" do
        expect {
          post content_artwork_metadata_path(content),
               params: valid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(ArtworkMetadata, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "with invalid parameters" do
      it "does not create artwork_metadata and shows error" do
        expect {
          post content_artwork_metadata_path(content), params: invalid_attributes
        }.not_to change(ArtworkMetadata, :count)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークメタデータの作成に失敗しました")
      end

      it "responds with unprocessable_content via Turbo Stream" do
        expect {
          post content_artwork_metadata_path(content),
               params: invalid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(ArtworkMetadata, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /contents/:content_id/artwork_metadata" do
    let!(:artwork_metadata) { create(:artwork_metadata, content: content) }
    let(:update_attributes) do
      {
        artwork_metadata: {
          positive_prompt: "updated beautiful landscape, ultra HD",
          negative_prompt: "updated blurry, noise"
        }
      }
    end

    context "with valid parameters" do
      it "updates artwork_metadata and redirects to content" do
        patch content_artwork_metadata_path(content), params: update_attributes
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークメタデータが更新されました")
        artwork_metadata.reload
        expect(artwork_metadata.positive_prompt).to eq("updated beautiful landscape, ultra HD")
        expect(artwork_metadata.negative_prompt).to eq("updated blurry, noise")
      end

      it "updates artwork_metadata via Turbo Stream" do
        patch content_artwork_metadata_path(content),
              params: update_attributes,
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "with invalid parameters" do
      let(:invalid_update_attributes) do
        {
          artwork_metadata: {
            positive_prompt: "",
            negative_prompt: ""
          }
        }
      end

      it "does not update and shows error" do
        patch content_artwork_metadata_path(content), params: invalid_update_attributes
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークメタデータの更新に失敗しました")
      end
    end
  end

  describe "DELETE /contents/:content_id/artwork_metadata" do
    let!(:artwork_metadata) { create(:artwork_metadata, content: content) }

    context "when deletion succeeds" do
      it "destroys artwork_metadata and redirects to content" do
        expect {
          delete content_artwork_metadata_path(content)
        }.to change(ArtworkMetadata, :count).by(-1)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("アートワークメタデータが削除されました")
      end

      it "destroys artwork_metadata via Turbo Stream" do
        expect {
          delete content_artwork_metadata_path(content),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(ArtworkMetadata, :count).by(-1)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "when artwork_metadata does not exist" do
      it "handles missing artwork_metadata gracefully" do
        artwork_metadata.destroy

        delete content_artwork_metadata_path(content)
        expect(response).to have_http_status(:not_found)

        delete content_artwork_metadata_path(content),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
