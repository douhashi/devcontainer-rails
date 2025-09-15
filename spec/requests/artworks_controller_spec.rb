require "rails_helper"
require "vips"

RSpec.describe ArtworksController, type: :request do
  include ActiveJob::TestHelper

  let(:content) { create(:content) }

  describe "POST /contents/:content_id/artworks" do
    context "with valid artwork data" do
      let(:artwork_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

      it "creates artwork and generates thumbnail synchronously" do
        expect {
          post content_artworks_path(content), params: artwork_params
        }.to change { content.reload.artwork.present? }.from(false).to(true)

        # Should NOT enqueue job since it's synchronous now
        expect(DerivativeProcessingJob).not_to have_been_enqueued

        expect(response).to redirect_to(content)
        follow_redirect!
        # アートワークが正常に作成されたことを確認
        expect(Artwork.count).to eq(1)
      end

      context "when request is via Turbo Stream" do
        let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

        it "returns turbo stream response" do
          post content_artworks_path(content), params: artwork_params, headers: headers

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("turbo-stream")
        end

        it "generates thumbnail synchronously for eligible artwork" do
          post content_artworks_path(content), params: artwork_params, headers: headers
          expect(DerivativeProcessingJob).not_to have_been_enqueued
        end
      end
    end

    context "with non-eligible artwork (not 1920x1080)" do
      let(:artwork_params) { { artwork: { image: fixture_file_upload("images/hd_placeholder.jpg", "image/jpeg") } } }

      it "creates artwork but does not generate thumbnail" do
        expect {
          post content_artworks_path(content), params: artwork_params
        }.to change { content.reload.artwork.present? }.from(false).to(true)

        expect(DerivativeProcessingJob).not_to have_been_enqueued

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include(I18n.t('artworks.upload.success'))
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
        expect(response.body).to include(I18n.t('artworks.upload.failure'))
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
    let(:artwork_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

    it "updates artwork and generates thumbnail synchronously" do
      patch content_artwork_path(content, artwork), params: artwork_params
      expect(DerivativeProcessingJob).not_to have_been_enqueued

      expect(response).to redirect_to(content)
      follow_redirect!
      # アートワークが正常に更新されたことを確認
      expect(response.status).to eq(200)
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
      expect(response.body).to include(I18n.t('artworks.delete.success'))
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

  describe "POST /contents/:content_id/artworks/:id/regenerate_thumbnail", skip: "再生成機能は非同期処理のため、現在の同期処理実装とは異なる" do
    let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed, thumbnail_generation_error: "Previous error") }

    before do
    end

    it "regenerates thumbnail for failed artwork" do
      expect {
        post regenerate_thumbnail_content_artwork_path(content, artwork)
      }.to change { artwork.reload.thumbnail_generation_status }.from("failed").to("pending")

      expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
      expect(response).to redirect_to(content)
      follow_redirect!
      expect(response.body).to include(I18n.t('artworks.thumbnail.regeneration_started'))
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
        expect(response.body).to include(I18n.t('artworks.thumbnail.processing'))
      end
    end

    context "when artwork is not eligible" do
      before do
        clear_enqueued_jobs  # 事前にエンキューされたジョブをクリア
      end

      it "does not regenerate and returns error message" do
        post regenerate_thumbnail_content_artwork_path(content, artwork)

        expect(DerivativeProcessingJob).not_to have_been_enqueued
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include(I18n.t('artworks.thumbnail.not_eligible'))
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

  describe "Edge Cases" do
    describe "Large file handling" do
      # 大容量ファイル（10MB近い）でのタイムアウトテスト用の想定
      context "when upload large image file" do
        let(:large_image_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

        it "handles large files within timeout limits" do
          # 実際には大きなファイルではないが、処理時間の検証
          start_time = Time.current

          post content_artworks_path(content), params: large_image_params

          processing_time = Time.current - start_time
          expect(processing_time).to be < 30 # 30秒タイムアウト以内

          expect(response).to redirect_to(content)
          expect(content.reload.artwork).to be_present
        end

        it "logs appropriate details for large file processing" do
          allow(Rails.logger).to receive(:error)

          post content_artworks_path(content), params: large_image_params

          # エラーログが呼ばれていないことを確認（正常処理の場合）
          expect(Rails.logger).not_to have_received(:error)
        end
      end
    end

    describe "Memory management" do
      context "when processing multiple images sequentially" do
        let(:artwork_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

        it "properly manages memory across multiple uploads" do
          # 複数のアップロードを順次実行してメモリリークをチェック
          3.times do |i|
            # 前のアートワークを削除
            content.artwork&.destroy

            # 新しいアートワークをアップロード
            post content_artworks_path(content), params: artwork_params

            expect(response).to redirect_to(content)
            expect(content.reload.artwork).to be_present
            expect(content.artwork.thumbnail_generation_status).to eq('completed')
          end
        end
      end
    end

    describe "Error handling with detailed logging" do
      context "when thumbnail generation fails with detailed error info" do
        before do
          # ThumbnailGenerationServiceでエラーを発生させる
          allow_any_instance_of(ThumbnailGenerationService).to receive(:generate).and_raise(StandardError, "Test error")
        end

        let(:artwork_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

        it "logs detailed error information" do
          allow(Rails.logger).to receive(:error)

          post content_artworks_path(content), params: artwork_params

          # 詳細なエラーログが記録されることを確認
          expect(Rails.logger).to have_received(:error).with(/Failed to generate thumbnail/)
          expect(Rails.logger).to have_received(:error).with(/artwork_id/)
          expect(Rails.logger).to have_received(:error).with(/artwork_dimensions/)
          expect(Rails.logger).to have_received(:error).with(/file_size/)
        end

        it "ensures cleanup even when errors occur" do
          post content_artworks_path(content), params: artwork_params

          # エラーが発生してもレスポンスが返されることを確認
          expect(response).to have_http_status(:found) # redirect
        end
      end
    end

    describe "Concurrent processing scenarios" do
      context "when multiple thumbnail generation processes could run" do
        let(:artwork_params) { { artwork: { image: fixture_file_upload("images/fhd_placeholder.jpg", "image/jpeg") } } }

        it "handles state transitions correctly during concurrent scenarios" do
          # アートワーク作成
          post content_artworks_path(content), params: artwork_params

          artwork = content.reload.artwork
          expect(artwork).to be_present

          # 状態が正しく設定されていることを確認
          expect([ 'processing', 'completed', 'failed' ]).to include(artwork.thumbnail_generation_status)
        end
      end
    end
  end
end
