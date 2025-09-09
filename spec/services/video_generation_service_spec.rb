require "rails_helper"
require "open3"

RSpec.describe VideoGenerationService, type: :service do
  let(:video) { create(:video) }
  let(:service) { described_class.new(video) }
  let(:audio_path) { Rails.root.join("spec/test_data/sample_audio.mp3").to_s }
  let(:artwork_path) { Rails.root.join("spec/test_data/sample_artwork.jpg").to_s }
  let(:output_path) { Rails.root.join("tmp/test_output.mp4").to_s }

  before do
    FileUtils.rm_f(output_path)
  end

  after do
    FileUtils.rm_f(output_path)
  end

  describe "#generate" do
    context "with valid inputs" do
      it "generates a video file successfully" do
        # Mock Open3.capture3 for FFmpeg command execution (external dependency)
        allow(Open3).to receive(:capture3).and_return([
          "ffmpeg output", # stdout
          "",              # stderr
          double("status", success?: true) # status
        ])

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:size).and_call_original
        allow(File).to receive(:size).with(output_path).and_return(1024 * 1024)

        ffmpeg_output_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(output_path).and_return(ffmpeg_output_movie)
        allow(ffmpeg_output_movie).to receive(:duration).and_return(10.0)
        allow(ffmpeg_output_movie).to receive(:resolution).and_return("1920x1080")

        metadata = service.generate(
          audio_path: audio_path,
          artwork_path: artwork_path,
          output_path: output_path
        )

        expect(metadata).to include(
          duration: 10.0,
          resolution: "1920x1080",
          file_size: 1024 * 1024
        )
      end

      it "calls progress callback when provided" do
        # Mock Open3.capture3 for FFmpeg command execution (external dependency)
        allow(Open3).to receive(:capture3).and_return([
          "ffmpeg output", # stdout
          "",              # stderr
          double("status", success?: true) # status
        ])

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:size).and_call_original
        allow(File).to receive(:size).with(output_path).and_return(1024 * 1024)

        ffmpeg_output_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(output_path).and_return(ffmpeg_output_movie)
        allow(ffmpeg_output_movie).to receive(:duration).and_return(10.0)
        allow(ffmpeg_output_movie).to receive(:resolution).and_return("1920x1080")

        progress_values = []
        service.generate(
          audio_path: audio_path,
          artwork_path: artwork_path,
          output_path: output_path
        ) do |progress|
          progress_values << progress
        end

        # New implementation calls progress callback once at the end with 1.0
        expect(progress_values).to eq([ 1.0 ])
      end
    end

    context "with invalid inputs" do
      context "when audio file does not exist" do
        it "raises an error" do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(audio_path).and_return(false)
          allow(File).to receive(:exist?).with(artwork_path).and_return(true)

          expect {
            service.generate(
              audio_path: audio_path,
              artwork_path: artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Audio file not found/)
        end
      end

      context "when artwork file does not exist" do
        it "raises an error" do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(audio_path).and_return(true)
          allow(File).to receive(:exist?).with(artwork_path).and_return(false)

          expect {
            service.generate(
              audio_path: audio_path,
              artwork_path: artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Artwork file not found/)
        end
      end

      context "when audio file has invalid format" do
        it "raises an error" do
          invalid_audio_path = Rails.root.join("spec/test_data/invalid_file.txt").to_s

          # Create a temporary invalid file
          File.write(invalid_audio_path, "invalid content")

          expect {
            service.generate(
              audio_path: invalid_audio_path,
              artwork_path: artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Invalid audio format/)

          # Clean up
          File.unlink(invalid_audio_path) if File.exist?(invalid_audio_path)
        end
      end

      context "when artwork file has invalid format" do
        it "raises an error" do
          invalid_artwork_path = Rails.root.join("spec/test_data/invalid_artwork.txt").to_s

          # Create a temporary invalid file
          File.write(invalid_artwork_path, "invalid content")

          expect {
            service.generate(
              audio_path: audio_path,
              artwork_path: invalid_artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Invalid artwork format/)

          # Clean up
          File.unlink(invalid_artwork_path) if File.exist?(invalid_artwork_path)
        end
      end
    end

    context "when ffmpeg encounters an error" do
      it "raises an error with ffmpeg message" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        # Mock Open3.capture3 for FFmpeg failure (external dependency)
        allow(Open3).to receive(:capture3).and_return([
          "ffmpeg output",                     # stdout
          "Invalid codec configuration",      # stderr
          double("status", success?: false)    # status
        ])

        expect {
          service.generate(
            audio_path: audio_path,
            artwork_path: artwork_path,
            output_path: output_path
          )
        }.to raise_error(VideoGenerationService::GenerationError, /FFmpeg error: FFmpeg command failed: Invalid codec configuration/)
      end
    end

    context "when output file is not created" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        # Mock Open3.capture3 for FFmpeg execution (external dependency)
        allow(Open3).to receive(:capture3).and_return([
          "ffmpeg output", # stdout
          "",              # stderr
          double("status", success?: true) # status
        ])

        allow(File).to receive(:exist?).with(output_path).and_return(false)

        expect {
          service.generate(
            audio_path: audio_path,
            artwork_path: artwork_path,
            output_path: output_path
          )
        }.to raise_error(VideoGenerationService::GenerationError, /Output file was not created/)
      end
    end

    context "when output file is empty" do
      it "raises an error" do
        # Mock Open3.capture3 for FFmpeg execution (external dependency)
        allow(Open3).to receive(:capture3).and_return([
          "ffmpeg output", # stdout
          "",              # stderr
          double("status", success?: true) # status
        ])

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:size).and_call_original
        allow(File).to receive(:size).with(output_path).and_return(0)

        expect {
          service.generate(
            audio_path: audio_path,
            artwork_path: artwork_path,
            output_path: output_path
          )
        }.to raise_error(VideoGenerationService::GenerationError, /Output file is empty/)
      end
    end
  end

  describe "#build_ffmpeg_command" do
    context "with MP3 audio" do
      it "returns command with audio copy codec" do
        mp3_path = "/path/to/audio.mp3"
        command = service.send(:build_ffmpeg_command, mp3_path, artwork_path, output_path)

        expected_command = [
          "ffmpeg",
          "-loop", "1",
          "-framerate", "1",
          "-i", artwork_path,
          "-i", mp3_path,
          "-c:v", "libx264",
          "-preset", "slow",
          "-crf", "18",
          "-c:a", "copy",
          "-r", "30",
          "-shortest",
          "-pix_fmt", "yuv420p",
          "-movflags", "+faststart",
          "-y",
          output_path
        ]

        expect(command).to eq(expected_command)
      end
    end

    context "with non-MP3 audio" do
      it "returns command with AAC encoding" do
        wav_path = "/path/to/audio.wav"
        command = service.send(:build_ffmpeg_command, wav_path, artwork_path, output_path)

        expected_command = [
          "ffmpeg",
          "-loop", "1",
          "-framerate", "1",
          "-i", artwork_path,
          "-i", wav_path,
          "-c:v", "libx264",
          "-preset", "slow",
          "-crf", "18",
          "-c:a", "aac",
          "-b:a", "192k",
          "-r", "30",
          "-shortest",
          "-pix_fmt", "yuv420p",
          "-movflags", "+faststart",
          "-y",
          output_path
        ]

        expect(command).to eq(expected_command)
      end
    end
  end

  describe "#validate_input_files!" do
    context "when both files are valid" do
      it "does not raise an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)
        allow(File).to receive(:size).with(audio_path).and_return(1024)
        allow(File).to receive(:size).with(artwork_path).and_return(2048)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.not_to raise_error
      end
    end

    context "when audio file is empty" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)
        allow(File).to receive(:size).with(audio_path).and_return(0)
        allow(File).to receive(:size).with(artwork_path).and_return(2048)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.to raise_error(VideoGenerationService::GenerationError, /Audio file is empty/)
      end
    end

    context "when artwork file is empty" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)
        allow(File).to receive(:size).with(audio_path).and_return(1024)
        allow(File).to receive(:size).with(artwork_path).and_return(0)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.to raise_error(VideoGenerationService::GenerationError, /Artwork file is empty/)
      end
    end

    context "when audio file does not exist" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(false)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)
        allow(File).to receive(:size).with(artwork_path).and_return(2048)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.to raise_error(VideoGenerationService::GenerationError, /Audio file not found/)
      end
    end

    context "when artwork file does not exist" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(false)
        allow(File).to receive(:size).with(audio_path).and_return(1024)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.to raise_error(VideoGenerationService::GenerationError, /Artwork file not found/)
      end
    end
  end
end
