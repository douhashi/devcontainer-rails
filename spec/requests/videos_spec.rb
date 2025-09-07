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
      context "when audio is missing" do
        before do
          create(:artwork, content: content)
        end

        it "redirects with error message" do
          post content_video_path(content)
          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成の前提条件が満たされていません")
        end
      end

      context "when artwork is missing" do
        before do
          create(:audio, :completed, content: content)
        end

        it "redirects with error message" do
          post content_video_path(content)
          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成の前提条件が満たされていません")
        end
      end
    end
  end

  describe "GET /contents/:content_id/video" do
    context "when video does not exist" do
      it "redirects with error message" do
        get content_video_path(content)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("動画が見つかりません")
      end
    end

    context "when video exists" do
      let(:video) { create(:video, content: content) }

      before do
        create(:audio, :completed, content: content)
        create(:artwork, content: content)
      end

      context "when video is pending" do
        before do
          video.update!(status: :pending)
        end

        it "redirects with pending message" do
          get content_video_path(content)
          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成待機中です")
        end
      end

      context "when video is processing" do
        before do
          video.update!(status: :processing)
        end

        it "redirects with processing message" do
          get content_video_path(content)
          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成中です")
        end
      end

      context "when video is completed" do
        before do
          video.update!(status: :completed)
        end

        it "shows video page" do
          get content_video_path(content)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(content.theme)
        end
      end

      context "when video generation failed" do
        before do
          video.update!(status: :failed, error_message: "ffmpeg error")
        end

        it "redirects with error message" do
          get content_video_path(content)
          expect(response).to redirect_to(content)
          follow_redirect!
          expect(response.body).to include("動画生成に失敗しました")
          expect(response.body).to include("ffmpeg error")
        end
      end
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
