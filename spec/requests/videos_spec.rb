require 'rails_helper'

RSpec.describe "Videos", type: :request do
  let(:content) { create(:content) }

  describe "POST /contents/:content_id/video" do
    context "when prerequisites are met" do
      before do
        create(:audio, :completed, content: content)
        create(:artwork, content: content)
      end

      context "when video does not exist yet" do
        it "creates a video and starts generation" do
          expect {
            post content_video_path(content)
          }.to change(Video, :count).by(1)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成を開始しました")
        end

        it "enqueues GenerateVideoJob" do
          expect {
            post content_video_path(content)
          }.to have_enqueued_job(GenerateVideoJob)
        end
      end

      context "when video already exists" do
        before do
          create(:video, content: content)
        end

        it "does not create another video" do
          expect {
            post content_video_path(content)
          }.not_to change(Video, :count)

          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画は既に存在します")
        end
      end
    end

    context "when prerequisites are not met" do
      it "redirects with error message for missing audio or artwork" do
        # Test missing audio (with artwork present)
        create(:artwork, content: content)
        post content_video_path(content)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("動画生成の前提条件が満たされていません")

        # Test missing artwork (with audio present) - using new content
        content2 = create(:content)
        create(:audio, :completed, content: content2)
        post content_video_path(content2)
        expect(response).to redirect_to(content2)
        follow_redirect!
        expect(response.body).to include("動画生成の前提条件が満たされていません")
      end
    end
  end

  describe "GET /contents/:content_id/video (deleted endpoint)" do
    it "returns 404 when trying to access video detail page" do
      get "/contents/#{content.id}/video"
      expect(response).to have_http_status(404)
    end
  end

  describe "DELETE /contents/:content_id/video" do
    context "when video exists" do
      let!(:video) { create(:video, content: content) }

      it "deletes the video" do
        expect {
          delete content_video_path(content)
        }.to change(Video, :count).by(-1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("動画が削除されました")
      end
    end

    context "when video does not exist" do
      it "redirects with error message" do
        delete content_video_path(content)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("削除する動画が見つかりません")
      end
    end
  end
end
