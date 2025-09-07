require 'rails_helper'

RSpec.describe GenerateAudioJob do
  let(:content) { create(:content, duration: 10) }
  let(:audio) { create(:audio, content: content, status: :pending) }
  let(:track1) { create(:track, content: content, status: :completed, duration: 180) }
  let(:track2) { create(:track, content: content, status: :completed, duration: 150) }
  let(:track3) { create(:track, content: content, status: :completed, duration: 200) }

  let(:job) { described_class.new }

  describe '#perform' do
    context 'with pending audio' do
      it 'starts audio generation' do
        expect(job).to receive(:start_generation)

        job.perform(audio.id)
      end
    end

    context 'with processing audio' do
      let(:processing_audio) { create(:audio, content: content, status: :processing) }

      it 'checks generation status' do
        expect(job).to receive(:check_generation_status)

        job.perform(processing_audio.id)
      end
    end

    context 'with completed audio' do
      let(:completed_audio) { create(:audio, content: content, status: :completed) }

      it 'does nothing' do
        expect(job).not_to receive(:start_generation)
        expect(job).not_to receive(:check_generation_status)

        job.perform(completed_audio.id)
      end
    end

    context 'with failed audio' do
      let(:failed_audio) { create(:audio, content: content, status: :failed) }

      it 'does nothing' do
        expect(job).not_to receive(:start_generation)
        expect(job).not_to receive(:check_generation_status)

        job.perform(failed_audio.id)
      end
    end

    context 'when audio not found' do
      it 'raises error' do
        expect {
          job.perform(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when error occurs' do
      before do
        allow(job).to receive(:start_generation).and_raise(StandardError, "Test error")
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

      it 'selects tracks and starts concatenation' do
        composition_service = instance_double(AudioCompositionService)
        concatenation_service = instance_double(AudioConcatenationService)

        selected_tracks = [ track1, track2 ]
        composition_result = {
          selected_tracks: selected_tracks,
          total_duration: 330,
          tracks_used: 2,
          target_duration: 600
        }

        allow(AudioCompositionService).to receive(:new).with(content).and_return(composition_service)
        allow(composition_service).to receive(:select_tracks).and_return(composition_result)

        allow(AudioConcatenationService).to receive(:new).with(selected_tracks).and_return(concatenation_service)
        allow(concatenation_service).to receive(:concatenate).and_return('/tmp/output.mp3')

        allow(job).to receive(:attach_audio_file)
        allow(job).to receive(:complete_generation)

        job.send(:start_generation)

        audio.reload
        expect(audio.processing?).to be true
        expect(audio.metadata['tracks_used']).to eq(2)
        expect(audio.metadata['total_duration']).to eq(330)
      end

      context 'when insufficient tracks' do
        let(:empty_content) { create(:content, duration: 60) }
        let(:empty_audio) { create(:audio, content: empty_content, status: :pending) }

        before do
          job.instance_variable_set(:@audio, empty_audio)
        end

        it 'marks audio as failed' do
          composition_service = instance_double(AudioCompositionService)
          allow(AudioCompositionService).to receive(:new).and_return(composition_service)
          allow(composition_service).to receive(:select_tracks).and_raise(AudioCompositionService::InsufficientTracksError, "No tracks")

          job.send(:start_generation)

          empty_audio.reload
          expect(empty_audio.failed?).to be true
          expect(empty_audio.metadata['error']).to include("No tracks")
        end
      end

      context 'when concatenation fails' do
        before do
          [ track1, track2 ]
        end

        it 'marks audio as failed' do
          composition_service = instance_double(AudioCompositionService)
          concatenation_service = instance_double(AudioConcatenationService)

          selected_tracks = [ track1, track2 ]
          composition_result = {
            selected_tracks: selected_tracks,
            total_duration: 330,
            tracks_used: 2,
            target_duration: 600
          }

          allow(AudioCompositionService).to receive(:new).and_return(composition_service)
          allow(composition_service).to receive(:select_tracks).and_return(composition_result)

          allow(AudioConcatenationService).to receive(:new).and_return(concatenation_service)
          allow(concatenation_service).to receive(:concatenate).and_raise(AudioConcatenationService::ConcatenationError, "FFmpeg failed")

          job.send(:start_generation)

          audio.reload
          expect(audio.failed?).to be true
          expect(audio.metadata['error']).to include("FFmpeg failed")
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
        # Mock the audio attachment to avoid Shrine validation
        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)
        allow(job).to receive(:analyze_and_store_duration)
        allow(File).to receive(:unlink)

        job.send(:attach_audio_file, temp_file_path)

        expect(audio).to have_received(:audio=)
      end

      it 'analyzes duration and updates record' do
        analysis_service = instance_double(AudioAnalysisService)
        allow(AudioAnalysisService).to receive(:new).and_return(analysis_service)
        allow(analysis_service).to receive(:analyze_duration).with(temp_file_path).and_return(180)

        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)
        allow(File).to receive(:unlink)

        job.send(:attach_audio_file, temp_file_path)

        expect(audio.metadata['duration']).to eq(180)
      end

      it 'cleans up temporary file' do
        allow(audio).to receive(:audio=)
        allow(audio).to receive(:save!)
        allow(job).to receive(:analyze_and_store_duration)

        expect(File).to receive(:unlink).with(temp_file_path).at_least(:once)

        job.send(:attach_audio_file, temp_file_path)
      end
    end

    describe '#complete_generation' do
      it 'marks audio as completed and logs success' do
        expect(Rails.logger).to receive(:info).with(/Successfully completed audio generation/)

        job.send(:complete_generation)

        audio.reload
        expect(audio.completed?).to be true
      end
    end
  end
end
