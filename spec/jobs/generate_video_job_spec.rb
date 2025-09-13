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
        it "starts generation process and completes successfully" do
          job = described_class.new

          # Mock external VideoGenerationService (which handles FFmpeg)
          service = instance_double(VideoGenerationService)
          allow(VideoGenerationService).to receive(:new).with(video).and_return(service)
          allow(service).to receive(:generate).and_return({
            duration: 10.0,
            resolution: "1920x1080",
            file_size: 1024 * 1024
          })

          # Create a proper video file with correct MIME type for Shrine
          video_file = Tempfile.new([ 'video', '.mp4' ])
          # Write MP4 header to simulate real video file
          video_file.write("\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42isom" + "fake video data")
          video_file.rewind

          allow(File).to receive(:open).and_call_original
          allow(File).to receive(:open).with(/video_.*\.mp4/, 'rb') do |&block|
            if block
              block.call(video_file)
            else
              video_file
            end
          end
          allow(File).to receive(:unlink)
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:size).and_return(1024 * 1024)

          # Mock the download methods to bypass Shrine
          allow(job).to receive(:download_audio_file).and_return(Rails.root.join('spec/test_data/sample_audio.mp3').to_s)
          allow(job).to receive(:download_artwork_file).and_return(Rails.root.join('spec/test_data/sample_artwork.jpg').to_s)

          # Use memory storage for Shrine (configured in shrine_helpers.rb)
          # The upload will work transparently with memory storage

          expect { job.perform(video.id) }.to change { video.reload.status }.from('pending').to('completed')

          video_file.close
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
      it "marks video as failed when generation fails" do
        job = described_class.new

        # Mock Shrine file download methods to simulate actual file download
        audio_test_file = Rails.root.join('spec/test_data/sample_audio.mp3')
        artwork_test_file = Rails.root.join('spec/test_data/sample_artwork.jpg')

        # Mock the download_audio_file and download_artwork_file to return paths but allow validation to pass
        allow(job).to receive(:download_audio_file).and_return(audio_test_file.to_s)
        allow(job).to receive(:download_artwork_file).and_return(artwork_test_file.to_s)

        # Mock external VideoGenerationService to simulate failure
        service = instance_double(VideoGenerationService)
        allow(VideoGenerationService).to receive(:new).with(video).and_return(service)
        allow(service).to receive(:generate).and_raise(VideoGenerationService::GenerationError.new("FFmpeg error: Invalid codec"))

        # Mock file operations
        allow(File).to receive(:unlink)

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
          it "validates successfully without raising error" do
            # Test actual validation logic without mocking internal methods
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

          it "raises error for missing audio" do
            # Test actual validation logic
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

          it "raises error for missing artwork" do
            # Test actual validation logic
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

      describe "#validate_downloaded_file" do
        let(:temp_file) { Rails.root.join('spec/test_data/sample_audio.mp3') }

        # Using actual test files - no cleanup needed

        context "when file exists and is valid" do
          it "validates file successfully" do
            expect { job.send(:validate_downloaded_file, temp_file.to_s) }.not_to raise_error
          end

          it "validates image file successfully" do
            expect { job.send(:validate_downloaded_file, Rails.root.join('spec/test_data/sample_artwork.jpg').to_s) }.not_to raise_error
          end
        end

        context "when file does not exist" do
          it "raises error" do
            expect { job.send(:validate_downloaded_file, "/nonexistent/file.mp3") }
              .to raise_error(StandardError, /Downloaded file does not exist/)
          end
        end

        context "when file is empty" do
          it "raises error" do
            empty_file = Rails.root.join('tmp/empty_test_file.mp3')
            File.write(empty_file, "")

            expect { job.send(:validate_downloaded_file, empty_file.to_s) }
              .to raise_error(StandardError, /Downloaded file is empty/)

            File.unlink(empty_file) if File.exist?(empty_file)
          end
        end
      end

      describe "#cleanup_temp_files" do
        context "when debug mode is disabled" do
          it "deletes temporary files" do
            temp_file = Tempfile.new([ 'test', '.mp3' ])
            temp_file.write("data")
            temp_file.close

            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with("VIDEO_GENERATION_DEBUG").and_return(nil)
            expect(File).to receive(:unlink).with(temp_file.path)

            job.send(:cleanup_temp_files, [ temp_file.path ])
          end
        end

        context "when debug mode is enabled" do
          it "preserves temporary files" do
            temp_file = Tempfile.new([ 'test', '.mp3' ])
            temp_file.write("data")
            temp_file.close

            allow(ENV).to receive(:[]).and_call_original
            allow(ENV).to receive(:[]).with("VIDEO_GENERATION_DEBUG").and_return("true")
            expect(File).not_to receive(:unlink)

            job.send(:cleanup_temp_files, [ temp_file.path ])
          end
        end
      end
    end
  end
end
