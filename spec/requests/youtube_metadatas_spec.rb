require 'rails_helper'

RSpec.describe "YoutubeMetadata", type: :request do
  let(:content) { create(:content) }
  let(:valid_attributes) do
    {
      youtube_metadata: {
        title: "Sample YouTube Title",
        description_en: "Sample English description",
        description_ja: "サンプル日本語説明",
        hashtags: "#lofi #music",
        status: "draft"
      }
    }
  end
  let(:invalid_attributes) do
    {
      youtube_metadata: {
        title: "",
        description_en: "",
        description_ja: "",
        hashtags: "",
        status: "draft"
      }
    }
  end

  before do
    I18n.locale = :ja
  end

  describe "POST /contents/:content_id/youtube_metadata" do
    context "with valid parameters" do
      it "creates youtube_metadata and redirects to content" do
        expect {
          post content_youtube_metadata_path(content), params: valid_attributes
        }.to change(YoutubeMetadata, :count).by(1)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube メタデータが作成されました")
      end

      it "creates youtube_metadata via Turbo Stream" do
        expect {
          post content_youtube_metadata_path(content),
               params: valid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(YoutubeMetadata, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "with invalid parameters" do
      it "does not create youtube_metadata and shows error" do
        expect {
          post content_youtube_metadata_path(content), params: invalid_attributes
        }.not_to change(YoutubeMetadata, :count)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube メタデータの作成に失敗しました")
      end

      it "responds with unprocessable_content via Turbo Stream" do
        expect {
          post content_youtube_metadata_path(content),
               params: invalid_attributes,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(YoutubeMetadata, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /contents/:content_id/youtube_metadata" do
    let!(:youtube_metadata) { create(:youtube_metadata, content: content) }
    let(:update_attributes) do
      {
        youtube_metadata: {
          title: "Updated Title",
          description_en: "Updated English description",
          description_ja: "更新された日本語説明",
          status: "ready"
        }
      }
    end

    context "with valid parameters" do
      it "updates youtube_metadata and redirects to content" do
        patch content_youtube_metadata_path(content), params: update_attributes
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube メタデータが更新されました")
        youtube_metadata.reload
        expect(youtube_metadata.title).to eq("Updated Title")
        expect(youtube_metadata.status).to eq("ready")
      end

      it "updates youtube_metadata via Turbo Stream" do
        patch content_youtube_metadata_path(content),
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
          youtube_metadata: {
            title: "",
            description_en: "",
            description_ja: ""
          }
        }
      end

      it "does not update and shows error" do
        patch content_youtube_metadata_path(content), params: invalid_update_attributes
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube メタデータの更新に失敗しました")
      end
    end
  end

  describe "DELETE /contents/:content_id/youtube_metadata" do
    let!(:youtube_metadata) { create(:youtube_metadata, content: content) }

    context "when deletion succeeds" do
      it "destroys youtube_metadata and redirects to content" do
        expect {
          delete content_youtube_metadata_path(content)
        }.to change(YoutubeMetadata, :count).by(-1)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("YouTube メタデータが削除されました")
      end

      it "destroys youtube_metadata via Turbo Stream" do
        expect {
          delete content_youtube_metadata_path(content),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(YoutubeMetadata, :count).by(-1)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
      end
    end

    context "when youtube_metadata does not exist" do
      it "handles missing youtube_metadata gracefully" do
        youtube_metadata.destroy

        delete content_youtube_metadata_path(content, youtube_metadata.id)
        expect(response).to have_http_status(:not_found)

        delete content_youtube_metadata_path(content, youtube_metadata.id),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
