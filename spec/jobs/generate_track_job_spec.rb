require 'rails_helper'

RSpec.describe GenerateTrackJob, type: :job do
  let(:track) { create(:track, status: :pending) }
  let(:kie_service) { instance_double(KieService) }

  before do
    allow(KieService).to receive(:new).and_return(kie_service)
    # Mock ApplicationController.render to avoid turbo_frame_tag error
    allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")
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

      it 'initializes status_history in metadata' do
        allow(kie_service).to receive(:generate_music).with(prompt: anything).and_return('task_123')

        described_class.perform_now(track.id)

        expect(track.reload.metadata['status_history']).to be_an(Array)
        expect(track.reload.metadata['status_history'].first).to include('status' => 'pending_to_processing')
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

        it 'logs status transition' do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({ 'status' => 'processing' })
          allow(Rails.logger).to receive(:info).and_call_original

          expect(Rails.logger).to receive(:info).with(/Status transition for Track ##{track.id}: processing/)

          described_class.perform_now(track.id)
        end

        it 'handles uppercase PROCESSING status' do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({ 'status' => 'PROCESSING' })

          expect {
            described_class.perform_now(track.id)
          }.to have_enqueued_job(described_class)
            .with(track.id)
        end

        it 'handles mixed case Processing status' do
          allow(kie_service).to receive(:get_task_status)
            .with('task_123')
            .and_return({ 'status' => 'Processing' })

          expect {
            described_class.perform_now(track.id)
          }.to have_enqueued_job(described_class)
            .with(track.id)
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
              'response' => {
                'sunoData' => [
                  {
                    'audioUrl' => audio_url,
                    'title' => 'Test Track',
                    'tags' => 'lo-fi,chill',
                    'duration' => 240.0
                  }
                ]
              }
            })
          allow(kie_service).to receive(:extract_music_data)
            .and_return({
              audio_url: audio_url,
              title: 'Test Track',
              tags: 'lo-fi,chill',
              duration: 240.0
            })
          allow(kie_service).to receive(:download_audio)
            .with(audio_url, anything)
            .and_return(audio_file.path)
          track.metadata['status_history'] = []
          track.save!
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

        it 'records status transition to completed' do
          described_class.perform_now(track.id)

          history = track.reload.metadata['status_history']
          expect(history).to be_an(Array)
          expect(history.last).to include('status' => 'processing_to_completed')
        end

        it 'stores music metadata' do
          described_class.perform_now(track.id)

          metadata = track.reload.metadata
          expect(metadata['music_title']).to eq('Test Track')
          expect(metadata['music_tags']).to eq('lo-fi,chill')
        end

        it 'includes music metadata in status history' do
          described_class.perform_now(track.id)

          history = track.reload.metadata['status_history']
          expect(history.last).to include(
            'music_title' => 'Test Track',
            'music_tags' => 'lo-fi,chill'
          )
        end

        it 'stores duration from API response' do
          described_class.perform_now(track.id)

          expect(track.reload.duration).to eq(240)
        end

        it 'analyzes duration when not provided by API' do
          # Override to not provide duration from API
          allow(kie_service).to receive(:extract_music_data)
            .and_return({
              audio_url: audio_url,
              title: 'Test Track',
              tags: 'lo-fi,chill',
              duration: nil
            })

          audio_analysis_service = instance_double(AudioAnalysisService)
          allow(AudioAnalysisService).to receive(:new).and_return(audio_analysis_service)
          allow(audio_analysis_service).to receive(:analyze_duration).and_return(185)

          described_class.perform_now(track.id)

          expect(track.reload.duration).to eq(185)
        end

        it 'does not re-enqueue itself' do
          expect {
            described_class.perform_now(track.id)
          }.not_to have_enqueued_job(described_class)
        end

        context 'with uppercase SUCCESS status' do
          before do
            allow(kie_service).to receive(:get_task_status)
              .with('task_123')
              .and_return({
                'status' => 'SUCCESS',
                'response' => {
                  'sunoData' => [
                    {
                      'audioUrl' => audio_url,
                      'title' => 'Test Track',
                      'tags' => 'lo-fi,chill',
                      'duration' => 240.0
                    }
                  ]
                }
              })
            allow(kie_service).to receive(:extract_music_data)
              .and_return({
                audio_url: audio_url,
                title: 'Test Track',
                tags: 'lo-fi,chill',
                duration: 240.0
              })
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
        end

        context 'with mixed case Success status' do
          before do
            allow(kie_service).to receive(:get_task_status)
              .with('task_123')
              .and_return({
                'status' => 'Success',
                'response' => {
                  'sunoData' => [
                    {
                      'audioUrl' => audio_url,
                      'title' => 'Test Track',
                      'tags' => 'lo-fi,chill',
                      'duration' => 240.0
                    }
                  ]
                }
              })
            allow(kie_service).to receive(:extract_music_data)
              .and_return({
                audio_url: audio_url,
                title: 'Test Track',
                tags: 'lo-fi,chill',
                duration: 240.0
              })
          end

          it 'updates track status to completed' do
            expect {
              described_class.perform_now(track.id)
            }.to change { track.reload.status }.from('processing').to('completed')
          end
        end

        context 'when task is completed but no audio URL found' do
          before do
            allow(kie_service).to receive(:get_task_status)
              .with('task_123')
              .and_return({
                'status' => 'completed',
                'response' => {
                  'sunoData' => []
                }
              })
            allow(kie_service).to receive(:extract_music_data)
              .and_return(nil)
          end

          it 'updates track status to failed' do
            expect {
              described_class.perform_now(track.id)
            }.to change { track.reload.status }.from('processing').to('failed')
          end

          it 'stores error in metadata' do
            described_class.perform_now(track.id)
            expect(track.reload.metadata['error']).to include('No audio URL in completed task response')
          end
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

        context 'with uppercase FAILED status' do
          before do
            allow(kie_service).to receive(:get_task_status)
              .with('task_123')
              .and_return({
                'status' => 'FAILED',
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
        end
      end
    end

    context 'when receiving unknown status' do
      before do
        track.update!(
          status: :processing,
          metadata: { 'task_id' => 'task_123', 'polling_attempts' => 5 }
        )
      end

      it 'logs warning with unknown status value' do
        allow(kie_service).to receive(:get_task_status)
          .with('task_123')
          .and_return({ 'status' => 'UNKNOWN_STATUS', 'extra_field' => 'some_value' })

        expect(Rails.logger).to receive(:warn).with(/Unknown task status: UNKNOWN_STATUS/)
        expect(Rails.logger).to receive(:warn).with(/Full response:.*UNKNOWN_STATUS/)

        described_class.perform_now(track.id)
      end

      it 'continues polling when status is unknown' do
        allow(kie_service).to receive(:get_task_status)
          .with('task_123')
          .and_return({ 'status' => 'PENDING' })

        expect {
          described_class.perform_now(track.id)
        }.to have_enqueued_job(described_class)
          .with(track.id)
      end

      it 'increments polling attempts for unknown status' do
        allow(kie_service).to receive(:get_task_status)
          .with('task_123')
          .and_return({ 'status' => 'IN_QUEUE' })

        expect {
          described_class.perform_now(track.id)
        }.to change { track.reload.metadata['polling_attempts'] }.from(5).to(6)
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

        expect(track.reload.metadata['error']).to eq('音楽生成がタイムアウトしました（10分経過）。処理に時間がかかっています。')
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
