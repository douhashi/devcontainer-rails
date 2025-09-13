require 'rails_helper'

RSpec.describe GenerateAudioJob do
  let(:content) { create(:content, duration_min: 10) }
  let(:audio) { create(:audio, content: content, status: :pending) }
  let(:track1) { create(:track, content: content, status: :completed, duration_sec: 300) }
  let(:track2) { create(:track, content: content, status: :completed, duration_sec: 200) }
  let(:track3) { create(:track, content: content, status: :completed, duration_sec: 150) }

  let(:job) { described_class.new }

  describe '#perform' do
    context 'with pending audio' do
      it 'starts audio generation and changes status' do
        # Ensure we have enough tracks available (need at least 600 seconds total)
        track1
        track2
        track3

        # Mock external file operations and dependencies only
        concatenation_service = instance_double(AudioConcatenationService)
        analysis_service = instance_double(AudioAnalysisService)

        allow(AudioConcatenationService).to receive(:new).and_return(concatenation_service)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)

        allow(concatenation_service).to receive(:concatenate).and_return('/tmp/output.mp3')
        allow(analysis_service).to receive(:analyze_duration).and_return(600)

        # Mock file operations and Shrine validation
        audio_file = Tempfile.new([ 'audio', '.mp3' ])
        audio_file.write('fake audio data')
        audio_file.rewind

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with('/tmp/output.mp3', 'rb') do |&block|
          block.call(audio_file) if block
          audio_file
        end
        allow(File).to receive(:unlink)

        # Use memory storage for Shrine (configured in shrine_helpers.rb)
        # The upload will work transparently with memory storage

        job.perform(audio.id)

        expect(audio.reload.status).to eq('completed')
      end
    end

    context 'with processing audio' do
      let(:processing_audio) { create(:audio, content: content, status: :processing) }

      it 'does nothing for processing audio' do
        # Processing audio should not be reprocessed
        expect(processing_audio.status).to eq('processing')
        job.perform(processing_audio.id)
        processing_audio.reload
        expect(processing_audio.status).to eq('processing')
      end
    end

    context 'with completed audio' do
      let(:completed_audio) { create(:audio, content: content, status: :completed) }

      it 'does nothing for completed audio' do
        expect(completed_audio.status).to eq('completed')
        job.perform(completed_audio.id)
        completed_audio.reload
        expect(completed_audio.status).to eq('completed')
      end
    end

    context 'with failed audio' do
      let(:failed_audio) { create(:audio, content: content, status: :failed) }

      it 'does nothing for failed audio' do
        expect(failed_audio.status).to eq('failed')
        job.perform(failed_audio.id)
        failed_audio.reload
        expect(failed_audio.status).to eq('failed')
      end
    end

    context 'when audio not found' do
      it 'raises error' do
        expect {
          job.perform(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when error occurs during generation' do
      before do
        # Mock service to raise error
        composition_service = instance_double(AudioCompositionService)
        allow(AudioCompositionService).to receive(:new).and_return(composition_service)
        allow(composition_service).to receive(:select_tracks).and_raise(StandardError, "Test error")
      end

      it 'handles error and marks audio as failed' do
        job.perform(audio.id)

        audio.reload
        expect(audio.failed?).to be true
        expect(audio.metadata['error']).to include("Job error: Test error")
      end
    end
  end

  describe 'private methods' do
    before do
      job.instance_variable_set(:@audio, audio)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    describe '#start_generation' do
      before do
        [ track1, track2, track3 ] # create tracks
      end

      it 'uses real services to select tracks and start concatenation' do
        # Ensure we have enough tracks (need at least 600 seconds)
        track1
        track2
        track3

        # Set the instance variable for the private method test
        job.instance_variable_set(:@audio, audio)

        # Test the actual business logic flow with minimal external mocking
        # Mock only file operations and external dependencies
        concatenation_service = instance_double(AudioConcatenationService)
        analysis_service = instance_double(AudioAnalysisService)

        allow(AudioConcatenationService).to receive(:new).and_return(concatenation_service)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)

        allow(concatenation_service).to receive(:concatenate).and_return('/tmp/output.mp3')
        allow(analysis_service).to receive(:analyze_duration).and_return(600)

        # Mock file operations and Shrine validation
        audio_file = Tempfile.new([ 'audio', '.mp3' ])
        audio_file.write('fake audio data')
        audio_file.rewind

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with('/tmp/output.mp3', 'rb') do |&block|
          block.call(audio_file) if block
          audio_file
        end
        allow(File).to receive(:unlink)

        # Use memory storage for Shrine (configured in shrine_helpers.rb)
        # The upload will work transparently with memory storage

        job.send(:start_generation)

        audio.reload
        expect(audio.status).to eq('completed')
      end

      context 'when insufficient tracks' do
        let(:empty_content) { create(:content, duration_min: 60) }
        let(:empty_audio) { create(:audio, content: empty_content, status: :pending) }

        before do
          job.instance_variable_set(:@audio, empty_audio)
        end

        it 'marks audio as failed when no tracks available' do
          # Test actual service behavior with insufficient tracks
          # The real AudioCompositionService should raise InsufficientTracksError
          # when no tracks are available
          job.send(:start_generation)

          empty_audio.reload
          expect(empty_audio.failed?).to be true
          expect(empty_audio.metadata['error']).to include("No completed tracks available")
        end
      end

      context 'when concatenation fails' do
        before do
          [ track1, track2 ]
        end

        it 'handles concatenation failure appropriately' do
          # Create enough tracks so composition service passes, but concatenation fails
          # Update content to have shorter target duration so tracks pass composition
          content.update!(duration_min: 5)  # 5 minutes = 300 seconds
          track1  # 180 seconds
          track2  # 150 seconds
          # Total: 330 seconds > 300 seconds target, so composition should pass

          # Mock only the concatenation service to fail
          concatenation_service = instance_double(AudioConcatenationService)
          allow(AudioConcatenationService).to receive(:new).and_return(concatenation_service)
          allow(concatenation_service).to receive(:concatenate).and_raise(AudioConcatenationService::ConcatenationError.new("FFmpeg failed"))

          job.send(:start_generation)

          audio.reload
          expect(audio.failed?).to be true
          expect(audio.metadata['error']).to include("Audio concatenation failed")
        end
      end
    end

    describe '#attach_audio_file' do
      let(:temp_file_path) { '/tmp/test_audio.mp3' }

      before do
        # Create a temporary file for testing
        File.write(temp_file_path, 'fake audio content')
      end

      after do
        File.unlink(temp_file_path) if File.exist?(temp_file_path)
      end

      it 'attaches the audio file to the audio record' do
        # Test actual file attachment behavior
        # Mock only the Shrine attachment to avoid file system operations in test
        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)
        allow(File).to receive(:unlink)

        # Mock external dependency (AudioAnalysisService)
        analysis_service = instance_double(AudioAnalysisService)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)
        allow(analysis_service).to receive(:analyze_duration).and_return(180)

        job.send(:attach_audio_file, temp_file_path)

        expect(audio).to have_received(:audio=)
        expect(audio.metadata['duration']).to eq(180)
      end

      it 'analyzes duration using external service' do
        # Mock external dependency only
        analysis_service = instance_double(AudioAnalysisService)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)
        allow(analysis_service).to receive(:analyze_duration).with(temp_file_path).and_return(180)

        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)
        allow(File).to receive(:unlink)

        job.send(:attach_audio_file, temp_file_path)

        expect(analysis_service).to have_received(:analyze_duration).with(temp_file_path)
        expect(audio.metadata['duration']).to eq(180)
      end

      it 'cleans up temporary file' do
        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)

        # Mock external dependency
        analysis_service = instance_double(AudioAnalysisService)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)
        allow(analysis_service).to receive(:analyze_duration).and_return(180)

        expect(File).to receive(:unlink).with(temp_file_path).at_least(:once)

        job.send(:attach_audio_file, temp_file_path)
      end
    end

    describe '#complete_generation' do
      it 'marks audio as completed and logs success' do
        expect(Rails.logger).to receive(:info).with(/Successfully completed audio generation/)

        job.send(:complete_generation)

        audio.reload
        expect(audio.status).to eq('completed')
      end
    end
  end
end
