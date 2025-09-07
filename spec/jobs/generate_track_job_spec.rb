require 'rails_helper'

RSpec.describe GenerateTrackJob, type: :job do
  let(:track) { create(:track, status: :pending) }
  let(:kie_service) { instance_double(KieService) }

  before do
    allow(KieService).to receive(:new).and_return(kie_service)
  end

  describe '#perform' do
    context 'when starting a new generation' do
      it 'updates track status to processing' do
        allow(kie_service).to receive(:generate_music).with(prompt: anything).and_return('task_123')

        expect {
          described_class.perform_now(track.id)
        }.to change { track.reload.status }.from('pending').to('processing')
      end

      it 'stores task_id in track metadata' do
        allow(kie_service).to receive(:generate_music).with(prompt: anything).and_return('task_123')

        described_class.perform_now(track.id)

        expect(track.reload.metadata['task_id']).to eq('task_123')
      end

      it 'generates music with content audio_prompt' do
        expect(kie_service).to receive(:generate_music)
          .with(prompt: track.content.audio_prompt)
          .and_return('task_123')

        described_class.perform_now(track.id)
      end

      it 're-enqueues itself for polling' do
        allow(kie_service).to receive(:generate_music).with(prompt: anything).and_return('task_123')

        expect {
          described_class.perform_now(track.id)
        }.to have_enqueued_job(described_class)
          .with(track.id)
      end
    end

    context 'when starting a new generation with custom audio prompt' do
      let(:content) { create(:content, audio_prompt: 'Custom lo-fi beat with jazz elements') }
      let(:track) { create(:track, status: :pending, content: content) }

      it 'generates music with content audio_prompt when provided' do
        expect(kie_service).to receive(:generate_music)
          .with(prompt: 'Custom lo-fi beat with jazz elements')
          .and_return('task_123')

        described_class.perform_now(track.id)
      end

      it 'uses default prompt when content has no audio_prompt' do
        content.update_column(:audio_prompt, '')

        expect(kie_service).to receive(:generate_music)
          .with(prompt: 'Create a relaxing lo-fi hip-hop beat for studying')
          .and_return('task_123')

        described_class.perform_now(track.id)
      end
    end

    context 'when polling for task status' do
      before do
        track.update!(
          status: :processing,
          metadata: { 'task_id' => 'task_123' }
        )
      end

      context 'when task is still processing' do
        it 're-enqueues itself for polling' do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({ 'status' => 'processing' })

          expect {
            described_class.perform_now(track.id)
          }.to have_enqueued_job(described_class)
            .with(track.id)
        end

        it 'does not change track status' do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({ 'status' => 'processing' })

          expect {
            described_class.perform_now(track.id)
          }.not_to change { track.reload.status }
        end
      end

      context 'when task is completed' do
        let(:audio_file) do
          file = Tempfile.new([ 'audio', '.mp3' ])
          # Write valid MP3 header
          file.write("\xFF\xFB\x90\x00" + "\x00" * 100)
          file.rewind
          file
        end
        let(:audio_url) { 'https://api.kie.ai/downloads/audio_123.mp3' }

        before do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({
              'status' => 'completed',
              'output' => { 'audio_url' => audio_url }
            })
          allow(kie_service).to receive(:download_audio)
            .with(audio_url, anything)
            .and_return(audio_file.path)
        end

        after do
          audio_file.close
          audio_file.unlink
        end

        it 'downloads the audio file' do
          expect(kie_service).to receive(:download_audio).with(audio_url, anything)

          described_class.perform_now(track.id)
        end

        it 'attaches the audio file to the track' do
          described_class.perform_now(track.id)

          expect(track.reload.audio).to be_present
        end

        it 'updates track status to completed' do
          expect {
            described_class.perform_now(track.id)
          }.to change { track.reload.status }.from('processing').to('completed')
        end

        it 'stores audio_url in metadata' do
          described_class.perform_now(track.id)

          expect(track.reload.metadata['audio_url']).to eq(audio_url)
        end

        it 'does not re-enqueue itself' do
          expect {
            described_class.perform_now(track.id)
          }.not_to have_enqueued_job(described_class)
        end
      end

      context 'when task has failed' do
        before do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({
              'status' => 'failed',
              'error' => 'Generation failed: Insufficient credits'
            })
        end

        it 'updates track status to failed' do
          expect {
            described_class.perform_now(track.id)
          }.to change { track.reload.status }.from('processing').to('failed')
        end

        it 'stores error message in metadata' do
          described_class.perform_now(track.id)

          expect(track.reload.metadata['error']).to eq('Generation failed: Insufficient credits')
        end

        it 'does not re-enqueue itself' do
          expect {
            described_class.perform_now(track.id)
          }.not_to have_enqueued_job(described_class)
        end
      end
    end

    context 'when track is already completed' do
      before do
        track.update!(status: :completed)
      end

      it 'does not process the track' do
        expect(kie_service).not_to receive(:generate_music)
        expect(kie_service).not_to receive(:get_task_status)

        described_class.perform_now(track.id)
      end
    end

    context 'when track is already failed' do
      before do
        track.update!(status: :failed)
      end

      it 'does not process the track' do
        expect(kie_service).not_to receive(:generate_music)
        expect(kie_service).not_to receive(:get_task_status)

        described_class.perform_now(track.id)
      end
    end

    context 'when maximum polling attempts exceeded' do
      before do
        track.update!(
          status: :processing,
          metadata: {
            'task_id' => 'task_123',
            'polling_attempts' => 20
          }
        )
      end

      it 'updates track status to failed' do
        expect {
          described_class.perform_now(track.id)
        }.to change { track.reload.status }.from('processing').to('failed')
      end

      it 'stores timeout error in metadata' do
        described_class.perform_now(track.id)

        expect(track.reload.metadata['error']).to eq('Task timed out after maximum polling attempts')
      end

      it 'does not re-enqueue itself' do
        expect {
          described_class.perform_now(track.id)
        }.not_to have_enqueued_job(described_class)
      end
    end

    context 'error handling' do
      context 'when KieService raises an error' do
        it 'handles network errors gracefully' do
          allow(kie_service).to receive(:generate_music)
            .and_raise(Kie::Errors::NetworkError, 'Connection failed')

          expect {
            described_class.perform_now(track.id) rescue nil
          }.to change { track.reload.status }.from('pending').to('failed')
        end

        it 'updates track status to failed on unexpected errors' do
          allow(kie_service).to receive(:generate_music)
            .and_raise(StandardError, 'Unexpected error')

          expect {
            described_class.perform_now(track.id) rescue nil
          }.to change { track.reload.status }.from('pending').to('failed')
        end

        it 'stores error message in metadata on unexpected errors' do
          allow(kie_service).to receive(:generate_music)
            .and_raise(StandardError, 'Unexpected error')

          described_class.perform_now(track.id) rescue nil

          expect(track.reload.metadata['error']).to include('Unexpected error')
        end
      end
    end
  end
end
