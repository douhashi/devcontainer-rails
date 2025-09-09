require 'rails_helper'

RSpec.describe GenerateVideoJob, type: :job do
  describe "concurrency control" do
    it "has limits_concurrency configured" do
      expect(described_class).to respond_to(:limits_concurrency)
    end

    it "uses video_generation concurrency key" do
      expect(described_class.concurrency_key).to eq("video_generation")
    end

    it "respects VIDEO_GENERATION_CONCURRENCY environment variable" do
      allow(ENV).to receive(:fetch).with("VIDEO_GENERATION_CONCURRENCY", "1").and_return("3")
      expect(described_class.concurrency_limit).to eq(3)
    end

    it "defaults to 1 concurrent job when environment variable is not set" do
      allow(ENV).to receive(:fetch).with("VIDEO_GENERATION_CONCURRENCY", "1").and_return("1")
      expect(described_class.concurrency_limit).to eq(1)
    end
  end

  describe "#perform" do
    let(:content) { create(:content) }
    let(:audio) { create(:audio, :completed, content: content) }
    let(:artwork) { create(:artwork, content: content) }
    let(:video) { create(:video, :pending, content: content) }

    before do
      audio
      artwork
    end

    context "when video is already completed or failed" do
      it "does not process completed video" do
        video.update!(status: :completed)
        expect(video).not_to receive(:update!)

        described_class.new.perform(video.id)
      end

      it "does not process failed video" do
        video.update!(status: :failed)
        expect(video).not_to receive(:update!)

        described_class.new.perform(video.id)
      end
    end

    context "when video is pending" do
      context "with valid prerequisites" do
        it "starts generation process" do
          job = described_class.new

          # Mock file operations
          allow(job).to receive(:download_audio_file).and_return('/tmp/test_audio.mp3')
          allow(job).to receive(:download_artwork_file).and_return('/tmp/test_artwork.jpg')

          # Mock VideoGenerationService
          service = instance_double(VideoGenerationService)
          allow(VideoGenerationService).to receive(:new).with(video).and_return(service)
          allow(service).to receive(:generate).and_return({
            duration: 10.0,
            resolution: "1920x1080",
            file_size: 1024 * 1024
          })

          allow(job).to receive(:attach_video_file)
          allow(job).to receive(:store_video_metadata)
          allow(job).to receive(:cleanup_temp_files)

          expect { job.perform(video.id) }.to change { video.reload.status }.from('pending').to('completed')
        end
      end

      context "with missing audio" do
        before do
          audio.destroy
        end

        it "fails with appropriate error message" do
          described_class.new.perform(video.id)

          video.reload
          expect(video.status).to eq('failed')
          expect(video.error_message).to include("Audio must be completed")
        end
      end

      context "with missing artwork" do
        before do
          artwork.destroy
        end

        it "fails with appropriate error message" do
          described_class.new.perform(video.id)

          video.reload
          expect(video.status).to eq('failed')
          expect(video.error_message).to include("Artwork must be set")
        end
      end

      context "with incomplete audio" do
        before do
          audio.update!(status: :pending)
        end

        it "fails with appropriate error message" do
          described_class.new.perform(video.id)

          video.reload
          expect(video.status).to eq('failed')
          expect(video.error_message).to include("Audio must be completed")
        end
      end
    end

    context "when VideoGenerationService fails" do
      it "marks video as failed" do
        job = described_class.new

        # Mock prerequisites validation
        allow(job).to receive(:validate_prerequisites)
        allow(video).to receive(:update!).with(status: :processing)

        # Mock file downloads
        allow(job).to receive(:download_audio_file).and_return('/tmp/test_audio.mp3')
        allow(job).to receive(:download_artwork_file).and_return('/tmp/test_artwork.jpg')

        # Mock VideoGenerationService failure
        service = instance_double(VideoGenerationService)
        allow(VideoGenerationService).to receive(:new).with(video).and_return(service)
        allow(service).to receive(:generate).and_raise(VideoGenerationService::GenerationError.new("FFmpeg error: Invalid codec"))
        allow(job).to receive(:cleanup_temp_files)

        job.perform(video.id)

        video.reload
        expect(video.status).to eq('failed')
        expect(video.error_message).to include("FFmpeg error: Invalid codec")
      end
    end

    describe "private methods" do
      let(:job) { described_class.new }

      before do
        job.instance_variable_set(:@video, video)
      end

      describe "#validate_prerequisites" do
        context "when prerequisites are met" do
          it "does not raise error" do
            expect { job.send(:validate_prerequisites) }.not_to raise_error
          end
        end

        context "when audio is missing" do
          let(:content_without_audio) { create(:content) }
          let(:artwork_without_audio) { create(:artwork, content: content_without_audio) }
          let(:video_without_audio) { create(:video, :pending, content: content_without_audio) }
          let(:job_without_audio) { described_class.new }

          before do
            artwork_without_audio
            job_without_audio.instance_variable_set(:@video, video_without_audio)
          end

          it "raises error" do
            expect { job_without_audio.send(:validate_prerequisites) }.to raise_error(StandardError, /Audio must be completed/)
          end
        end

        context "when artwork is missing" do
          let(:content_without_artwork) { create(:content) }
          let(:audio_without_artwork) { create(:audio, :completed, content: content_without_artwork) }
          let(:video_without_artwork) { create(:video, :pending, content: content_without_artwork) }
          let(:job_without_artwork) { described_class.new }

          before do
            audio_without_artwork
            job_without_artwork.instance_variable_set(:@video, video_without_artwork)
          end

          it "raises error" do
            expect { job_without_artwork.send(:validate_prerequisites) }.to raise_error(StandardError, /Artwork must be set/)
          end
        end
      end

      describe "#generate_output_path" do
        it "generates valid output path" do
          path = job.send(:generate_output_path)
          expect(path).to match(%r{tmp/video_\d+_\d{8}_\d{6}\.mp4$})
        end
      end
    end
  end
end
