require 'rails_helper'
require 'tempfile'

RSpec.describe AudioConcatenationService do
  let(:content) { create(:content) }
  let(:track1) { create(:track, content: content, status: :completed) }
  let(:track2) { create(:track, content: content, status: :completed) }
  let(:tracks) { [ track1, track2 ] }

  let(:service) { described_class.new(tracks) }

  before do
    # Create temporary audio files for testing
    @temp_files = []
    tracks.each do |track|
      temp_file = Tempfile.new([ 'test_audio', '.mp3' ])
      temp_file.write("fake audio content for testing")
      temp_file.close

      # Mock the track's audio file path using Shrine API
      allow(track).to receive_message_chain(:audio, :id).and_return("mock_audio_id")
      allow(track).to receive_message_chain(:audio, :storage, :path).with("mock_audio_id").and_return(Pathname.new(temp_file.path))
      allow(track).to receive_message_chain(:audio, :exists?).and_return(true)

      @temp_files << temp_file
    end
  end

  after do
    @temp_files.each(&:unlink)
  end

  describe 'initialization' do
    it 'sets tracks' do
      expect(service.tracks).to eq(tracks)
    end

    it 'raises error with empty tracks' do
      expect {
        described_class.new([])
      }.to raise_error(AudioConcatenationService::InvalidTracksError, "No tracks provided for concatenation")
    end

    it 'raises error with nil tracks' do
      expect {
        described_class.new(nil)
      }.to raise_error(AudioConcatenationService::InvalidTracksError, "No tracks provided for concatenation")
    end
  end

  describe '#concatenate' do
    let(:output_path) { Rails.root.join('tmp', 'test_output.mp3') }

    before do
      # Mock ffmpeg command execution
      allow(service).to receive(:system).and_return(true)

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(output_path))

      # Create fake output file
      File.write(output_path, "concatenated audio content")
    end

    after do
      File.unlink(output_path) if File.exist?(output_path)
    end

    it 'concatenates audio files successfully' do
      result = service.concatenate(output_path)

      expect(result).to eq(output_path)
      expect(File.exist?(output_path)).to be true
    end

    it 'creates playlist file for ffmpeg' do
      expect(service).to receive(:create_playlist_file).and_call_original

      service.concatenate(output_path)
    end

    it 'executes ffmpeg command' do
      expect(service).to receive(:system).with(/ffmpeg -f concat -safe 0 -i .* -c copy -y #{Regexp.escape(output_path.to_s)}/).and_return(true)

      service.concatenate(output_path)
    end

    it 'cleans up playlist file after concatenation' do
      original_method = service.method(:create_playlist_file)
      playlist_path = nil

      allow(service).to receive(:create_playlist_file) do
        playlist_path = original_method.call
        playlist_path
      end

      service.concatenate(output_path)

      expect(File.exist?(playlist_path)).to be false
    end

    context 'when ffmpeg fails' do
      before do
        allow(service).to receive(:system).and_return(false)
      end

      it 'raises concatenation error' do
        expect {
          service.concatenate(output_path)
        }.to raise_error(AudioConcatenationService::ConcatenationError, /Failed to concatenate audio files/)
      end

      it 'still cleans up playlist file' do
        original_method = service.method(:create_playlist_file)
        playlist_path = nil

        allow(service).to receive(:create_playlist_file) do
          playlist_path = original_method.call
          playlist_path
        end

        expect {
          service.concatenate(output_path)
        }.to raise_error(AudioConcatenationService::ConcatenationError)

        expect(File.exist?(playlist_path)).to be false
      end
    end

    context 'when tracks have no audio files' do
      let(:track_without_audio) { create(:track, content: content, status: :completed) }
      let(:service_no_audio) { described_class.new([ track_without_audio ]) }

      before do
        allow(track_without_audio).to receive_message_chain(:audio, :exists?).and_return(false)
      end

      it 'raises error for missing audio files' do
        expect {
          service_no_audio.concatenate(output_path)
        }.to raise_error(AudioConcatenationService::MissingAudioFileError)
      end
    end
  end

  describe 'private methods' do
    describe '#create_playlist_file' do
      it 'creates a playlist file with correct format' do
        playlist_path = service.send(:create_playlist_file)

        expect(File.exist?(playlist_path)).to be true

        content = File.read(playlist_path)
        tracks.each do |track|
          audio_path = track.audio.storage.path(track.audio.id).to_s
          expect(content).to include("file '#{audio_path}'")
        end

        File.unlink(playlist_path)
      end
    end

    describe '#validate_audio_files!' do
      context 'when all tracks have audio files' do
        it 'does not raise error' do
          expect {
            service.send(:validate_audio_files!)
          }.not_to raise_error
        end
      end

      context 'when some tracks have no audio files' do
        let(:track_without_audio) { create(:track, content: content, status: :completed) }

        before do
          allow(track_without_audio).to receive_message_chain(:audio, :exists?).and_return(false)
          service.instance_variable_set(:@tracks, tracks + [ track_without_audio ])
        end

        it 'raises missing audio file error' do
          expect {
            service.send(:validate_audio_files!)
          }.to raise_error(AudioConcatenationService::MissingAudioFileError)
        end
      end
    end
  end

  describe 'logging' do
    let(:output_path) { Rails.root.join('tmp', 'test_output.mp3') }

    before do
      allow(service).to receive(:system).and_return(true)
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, "concatenated audio content")
    end

    after do
      File.unlink(output_path) if File.exist?(output_path)
    end

    it 'logs concatenation progress' do
      expect(Rails.logger).to receive(:info).with(/Starting audio concatenation for \d+ tracks/)
      expect(Rails.logger).to receive(:info).with(/Audio concatenation completed/)

      service.concatenate(output_path)
    end
  end
end
