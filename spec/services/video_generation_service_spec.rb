require "rails_helper"

RSpec.describe VideoGenerationService, type: :service do
  let(:video) { create(:video) }
  let(:service) { described_class.new(video) }
  let(:audio_path) { Rails.root.join("spec/fixtures/files/sample.mp3").to_s }
  let(:artwork_path) { Rails.root.join("spec/fixtures/files/sample.jpg").to_s }
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
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        ffmpeg_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(audio_path).and_return(ffmpeg_movie)
        allow(ffmpeg_movie).to receive(:transcode).and_return(true)
        allow(File).to receive(:exist?).with(output_path).and_return(true)
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
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        ffmpeg_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(audio_path).and_return(ffmpeg_movie)

        progress_values = []
        allow(ffmpeg_movie).to receive(:transcode) do |_, _, _, &block|
          [ 0.1, 0.5, 1.0 ].each { |value| block&.call(value) }
          true
        end

        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:size).with(output_path).and_return(1024 * 1024)

        ffmpeg_output_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(output_path).and_return(ffmpeg_output_movie)
        allow(ffmpeg_output_movie).to receive(:duration).and_return(10.0)
        allow(ffmpeg_output_movie).to receive(:resolution).and_return("1920x1080")

        service.generate(
          audio_path: audio_path,
          artwork_path: artwork_path,
          output_path: output_path
        ) do |progress|
          progress_values << progress
        end

        expect(progress_values).to eq([ 0.1, 0.5, 1.0 ])
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
          invalid_audio_path = "/path/to/file.txt"
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(invalid_audio_path).and_return(true)
          allow(File).to receive(:exist?).with(artwork_path).and_return(true)

          expect {
            service.generate(
              audio_path: invalid_audio_path,
              artwork_path: artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Invalid audio format/)
        end
      end

      context "when artwork file has invalid format" do
        it "raises an error" do
          invalid_artwork_path = "/path/to/file.txt"
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(audio_path).and_return(true)
          allow(File).to receive(:exist?).with(invalid_artwork_path).and_return(true)

          expect {
            service.generate(
              audio_path: audio_path,
              artwork_path: invalid_artwork_path,
              output_path: output_path
            )
          }.to raise_error(VideoGenerationService::GenerationError, /Invalid artwork format/)
        end
      end
    end

    context "when ffmpeg encounters an error" do
      it "raises an error with ffmpeg message" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        ffmpeg_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(audio_path).and_return(ffmpeg_movie)
        allow(ffmpeg_movie).to receive(:transcode)
          .and_raise(FFMPEG::Error, "Invalid codec configuration")

        expect {
          service.generate(
            audio_path: audio_path,
            artwork_path: artwork_path,
            output_path: output_path
          )
        }.to raise_error(VideoGenerationService::GenerationError, /FFmpeg error: Invalid codec configuration/)
      end
    end

    context "when output file is not created" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        ffmpeg_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(audio_path).and_return(ffmpeg_movie)
        allow(ffmpeg_movie).to receive(:transcode).and_return(true)
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
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        ffmpeg_movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).with(audio_path).and_return(ffmpeg_movie)
        allow(ffmpeg_movie).to receive(:transcode).and_return(true)
        allow(File).to receive(:exist?).with(output_path).and_return(true)
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

  describe "#build_transcoding_options" do
    it "returns correct transcoding options" do
      options = service.send(:build_transcoding_options)

      expect(options).to eq({
        video_codec: "libx264",
        audio_codec: "aac",
        resolution: "1920x1080",
        video_bitrate: "5000k",
        audio_bitrate: "192k",
        audio_sample_rate: 48000,
        custom: %w[-loop 1 -framerate 30 -preset slow -crf 18 -shortest -pix_fmt yuv420p]
      })
    end
  end

  describe "#build_encoding_options" do
    it "returns correct encoding options with artwork path" do
      options = service.send(:build_encoding_options, artwork_path)

      expect(options).to eq({
        input_options: [ "-loop", "1", "-i", artwork_path ]
      })
    end
  end

  describe "#validate_input_files!" do
    context "when both files are valid" do
      it "does not raise an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(true)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.not_to raise_error
      end
    end

    context "when audio file does not exist" do
      it "raises an error" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(audio_path).and_return(false)
        allow(File).to receive(:exist?).with(artwork_path).and_return(true)

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

        expect {
          service.send(:validate_input_files!, audio_path, artwork_path)
        }.to raise_error(VideoGenerationService::GenerationError, /Artwork file not found/)
      end
    end
  end
end
