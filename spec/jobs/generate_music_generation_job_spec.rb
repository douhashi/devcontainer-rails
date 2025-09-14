require 'rails_helper'

RSpec.describe GenerateMusicGenerationJob, type: :job do
  include ActiveJob::TestHelper

  let(:content) { create(:content) }
  let(:music_generation) { create(:music_generation, content: content, status: :pending) }
  let(:kie_service) { instance_double(KieService) }

  before do
    allow(KieService).to receive(:new).and_return(kie_service)
    # Mock ActionCable broadcast to prevent errors during test
    allow(ActionCable.server).to receive(:broadcast).and_return(true)
  end

  describe '#perform' do
    context 'when generation is successful' do
      let(:task_id) { 'test-task-id-123' }
      let(:api_response) do
        {
          'taskId' => task_id,
          'status' => 'completed',
          'response' => {
            'sunoData' => [
              {
                'audioUrl' => 'https://example.com/audio1.mp3',
                'title' => 'Track 1',
                'tags' => 'lo-fi,chill',
                'duration' => 120.0,
                'modelName' => 'chirp-v3-5',
                'prompt' => '[Verse] Test prompt 1',
                'audioId' => 'audio-id-1'
              },
              {
                'audioUrl' => 'https://example.com/audio2.mp3',
                'title' => 'Track 2',
                'tags' => 'lo-fi,chill',
                'duration' => 125.0,
                'modelName' => 'chirp-v3-5',
                'prompt' => '[Verse] Test prompt 2',
                'audioId' => 'audio-id-2'
              }
            ]
          }
        }
      end
      let(:music_data) do
        [
          {
            audio_url: 'https://example.com/audio1.mp3',
            title: 'Track 1',
            tags: 'lo-fi,chill',
            duration: 120.0,
            model_name: 'chirp-v3-5',
            generated_prompt: '[Verse] Test prompt 1',
            audio_id: 'audio-id-1'
          },
          {
            audio_url: 'https://example.com/audio2.mp3',
            title: 'Track 2',
            tags: 'lo-fi,chill',
            duration: 125.0,
            model_name: 'chirp-v3-5',
            generated_prompt: '[Verse] Test prompt 2',
            audio_id: 'audio-id-2'
          }
        ]
      end

      before do
        # Mock external KIE.AI API calls
        allow(kie_service).to receive(:generate_music).and_return(task_id)
        allow(kie_service).to receive(:get_task_status).and_return(api_response)
        allow(kie_service).to receive(:extract_all_music_data).and_return(music_data)
        # Mock external file download operation
        allow(kie_service).to receive(:download_audio) do |url, path|
          # Copy sample MP3 file to the expected path for testing
          FileUtils.cp(Rails.root.join('spec/fixtures/files/audio/sample.mp3'), path)
          path
        end
      end

      it 'updates music_generation status to completed' do
        # Temporarily enable error raising to see the actual error
        allow(Rails.logger).to receive(:error) do |msg|
          puts "ERROR LOG: #{msg}"
        end

        GenerateMusicGenerationJob.perform_now(music_generation.id)

        music_generation.reload
        puts "Status: #{music_generation.status}, API Response: #{music_generation.api_response.present?}"
        puts "Tracks count: #{music_generation.tracks.count}"
        puts "Track statuses: #{music_generation.tracks.pluck(:status).join(', ')}"
        expect(music_generation.status).to eq('completed')
      end

      it 'creates two tracks with correct metadata' do
        expect {
          GenerateMusicGenerationJob.perform_now(music_generation.id)
        }.to change(Track, :count).by(2)

        tracks = music_generation.reload.tracks.order(:variant_index)

        expect(tracks[0].variant_index).to eq(0)
        expect(tracks[0].metadata['music_title']).to eq('Track 1')
        expect(tracks[0].metadata['audio_id']).to eq('audio-id-1')
        expect(tracks[0].duration_sec).to eq(120)

        expect(tracks[1].variant_index).to eq(1)
        expect(tracks[1].metadata['music_title']).to eq('Track 2')
        expect(tracks[1].metadata['audio_id']).to eq('audio-id-2')
        expect(tracks[1].duration_sec).to eq(125)
      end

      it 'saves api_response to music_generation' do
        GenerateMusicGenerationJob.perform_now(music_generation.id)
        expect(music_generation.reload.api_response).to eq(api_response)
      end

      it 'downloads audio files for each track' do
        expect(kie_service).to receive(:download_audio).twice
        GenerateMusicGenerationJob.perform_now(music_generation.id)
      end

      it 'marks tracks as completed' do
        GenerateMusicGenerationJob.perform_now(music_generation.id)
        tracks = music_generation.reload.tracks
        expect(tracks.all? { |t| t.status == 'completed' }).to be true
      end

      it 'saves request parameters to music_generation' do
        GenerateMusicGenerationJob.perform_now(music_generation.id)
        expect(music_generation.reload.request_params).to eq({
          'prompt' => music_generation.prompt,
          'model' => 'V4_5PLUS',
          'instrumental' => true,
          'wait_audio' => false
        })
      end

      it 'uses the generation_model from music_generation if present' do
        music_generation.update!(generation_model: 'V3_5')
        expect(kie_service).to receive(:generate_music).with(
          hash_including(model: 'V3_5')
        ).and_return(task_id)
        GenerateMusicGenerationJob.perform_now(music_generation.id)
      end
    end

    context 'when generation fails' do
      let(:error_message) { 'API error occurred' }

      before do
        # Mock external KIE.AI API to simulate failure
        allow(kie_service).to receive(:generate_music).and_raise(Kie::Errors::ApiError.new(error_message))
      end

      it 'marks music_generation as failed' do
        GenerateMusicGenerationJob.perform_now(music_generation.id)
        expect(music_generation.reload.status).to eq('failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to generate music for MusicGeneration/)
        # Also allow other error messages to be logged
        allow(Rails.logger).to receive(:error)
        GenerateMusicGenerationJob.perform_now(music_generation.id)
      end

      it 'does not create any tracks' do
        expect {
          GenerateMusicGenerationJob.perform_now(music_generation.id)
        }.not_to change(Track, :count)
      end
    end

    context 'when only one track is returned' do
      let(:task_id) { 'test-task-id-single' }
      let(:api_response) do
        {
          'taskId' => task_id,
          'status' => 'completed',
          'response' => {
            'sunoData' => [
              {
                'audioUrl' => 'https://example.com/audio1.mp3',
                'title' => 'Single Track',
                'tags' => 'lo-fi,chill',
                'duration' => 120.0,
                'modelName' => 'chirp-v3-5',
                'prompt' => '[Verse] Single prompt',
                'audioId' => 'audio-id-single'
              }
            ]
          }
        }
      end
      let(:music_data) do
        [
          {
            audio_url: 'https://example.com/audio1.mp3',
            title: 'Single Track',
            tags: 'lo-fi,chill',
            duration: 120.0,
            model_name: 'chirp-v3-5',
            generated_prompt: '[Verse] Single prompt',
            audio_id: 'audio-id-single'
          }
        ]
      end

      before do
        # Mock external KIE.AI API calls for single track case
        allow(kie_service).to receive(:generate_music).and_return(task_id)
        allow(kie_service).to receive(:get_task_status).and_return(api_response)
        allow(kie_service).to receive(:extract_all_music_data).and_return(music_data)
        # Mock external file download operation
        allow(kie_service).to receive(:download_audio) do |url, path|
          FileUtils.cp(Rails.root.join('spec/fixtures/files/audio/sample.mp3'), path)
          path
        end
      end

      it 'creates only one track' do
        expect {
          GenerateMusicGenerationJob.perform_now(music_generation.id)
        }.to change(Track, :count).by(1)

        track = music_generation.reload.tracks.first
        expect(track.variant_index).to eq(0)
      end
    end

    context 'when music_generation does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          GenerateMusicGenerationJob.perform_now(999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when music_generation is already completed' do
      let(:music_generation) { create(:music_generation, content: content, status: :completed) }

      it 'does not process the generation' do
        expect(kie_service).not_to receive(:generate_music)
        GenerateMusicGenerationJob.perform_now(music_generation.id)
      end
    end
  end

  describe '#poll_for_completion' do
    let(:task_id) { 'test-task-id-uppercase' }
    let(:job) { described_class.new }
    let(:music_generation) { create(:music_generation, content: content, status: :processing, task_id: task_id) }

    before do
      # Set up job instance variables for testing private methods
      job.instance_variable_set(:@music_generation, music_generation)
      job.instance_variable_set(:@kie_service, kie_service)
    end

    context 'with uppercase SUCCESS status from KIE API' do
      let(:api_response_success) do
        {
          'taskId' => task_id,
          'status' => 'SUCCESS',
          'response' => {
            'sunoData' => [
              {
                'audioUrl' => 'https://example.com/audio1.mp3',
                'title' => 'Track 1',
                'tags' => 'lo-fi,chill',
                'duration' => 120.0,
                'modelName' => 'V4_5PLUS',
                'prompt' => '[Verse] Test prompt 1',
                'audioId' => 'audio-id-1'
              }
            ]
          }
        }
      end

      before do
        # Mock external KIE.AI API response
        allow(kie_service).to receive(:get_task_status).and_return(api_response_success)
      end

      it 'recognizes uppercase SUCCESS status and completes polling' do
        expect { job.send(:poll_for_completion) }.not_to raise_error
        expect(job.instance_variable_get(:@task_data)).to eq(api_response_success)
      end
    end

    context 'with uppercase PENDING status from KIE API' do
      let(:api_response_pending) { { 'taskId' => task_id, 'status' => 'PENDING' } }
      let(:api_response_success) do
        {
          'taskId' => task_id,
          'status' => 'SUCCESS',
          'response' => { 'sunoData' => [] }
        }
      end

      before do
        call_count = 0
        allow(kie_service).to receive(:get_task_status) do
          call_count += 1
          call_count == 1 ? api_response_pending : api_response_success
        end
      end

      it 'continues polling when status is PENDING and completes on SUCCESS' do
        expect { job.send(:poll_for_completion) }.not_to raise_error
        expect(job.instance_variable_get(:@task_data)).to eq(api_response_success)
      end
    end

    context 'with uppercase error statuses from KIE API' do
      context 'CREATE_TASK_FAILED status' do
        let(:api_response_error) do
          {
            'taskId' => task_id,
            'status' => 'CREATE_TASK_FAILED',
            'error' => 'Task creation failed due to invalid parameters'
          }
        end

        before do
          allow(kie_service).to receive(:get_task_status).and_return(api_response_error)
        end

        it 'raises TaskFailedError for CREATE_TASK_FAILED status' do
          expect { job.send(:poll_for_completion) }.to raise_error(Kie::Errors::TaskFailedError, 'Task creation failed due to invalid parameters')
        end
      end

      context 'GENERATE_AUDIO_FAILED status' do
        let(:api_response_error) do
          {
            'taskId' => task_id,
            'status' => 'GENERATE_AUDIO_FAILED',
            'error' => 'Audio generation failed'
          }
        end

        before do
          allow(kie_service).to receive(:get_task_status).and_return(api_response_error)
        end

        it 'raises TaskFailedError for GENERATE_AUDIO_FAILED status' do
          expect { job.send(:poll_for_completion) }.to raise_error(Kie::Errors::TaskFailedError, 'Audio generation failed')
        end
      end

      context 'SENSITIVE_WORD_ERROR status' do
        let(:api_response_error) do
          {
            'taskId' => task_id,
            'status' => 'SENSITIVE_WORD_ERROR',
            'error' => 'Content contains sensitive words'
          }
        end

        before do
          allow(kie_service).to receive(:get_task_status).and_return(api_response_error)
        end

        it 'raises TaskFailedError for SENSITIVE_WORD_ERROR status' do
          expect { job.send(:poll_for_completion) }.to raise_error(Kie::Errors::TaskFailedError, 'Content contains sensitive words')
        end
      end
    end

    context 'with partial completion statuses' do
      context 'FIRST_SUCCESS status' do
        let(:api_response_first) do
          {
            'taskId' => task_id,
            'status' => 'FIRST_SUCCESS',
            'response' => { 'sunoData' => [ { 'audioUrl' => 'https://example.com/audio1.mp3' } ] }
          }
        end
        let(:api_response_success) do
          {
            'taskId' => task_id,
            'status' => 'SUCCESS',
            'response' => { 'sunoData' => [] }
          }
        end

        before do
          call_count = 0
          allow(kie_service).to receive(:get_task_status) do
            call_count += 1
            call_count == 1 ? api_response_first : api_response_success
          end
        end

        it 'continues polling when status is FIRST_SUCCESS and completes on SUCCESS' do
          expect { job.send(:poll_for_completion) }.not_to raise_error
          expect(job.instance_variable_get(:@task_data)).to eq(api_response_success)
        end
      end

      context 'TEXT_SUCCESS status' do
        let(:api_response_text) do
          {
            'taskId' => task_id,
            'status' => 'TEXT_SUCCESS'
          }
        end
        let(:api_response_success) do
          {
            'taskId' => task_id,
            'status' => 'SUCCESS',
            'response' => { 'sunoData' => [] }
          }
        end

        before do
          call_count = 0
          allow(kie_service).to receive(:get_task_status) do
            call_count += 1
            call_count == 1 ? api_response_text : api_response_success
          end
        end

        it 'continues polling when status is TEXT_SUCCESS and completes on SUCCESS' do
          expect { job.send(:poll_for_completion) }.not_to raise_error
          expect(job.instance_variable_get(:@task_data)).to eq(api_response_success)
        end
      end
    end

    context 'backward compatibility with lowercase statuses' do
      let(:api_response_lowercase_success) do
        {
          'taskId' => task_id,
          'status' => 'completed',
          'response' => { 'sunoData' => [] }
        }
      end

      before do
        allow(kie_service).to receive(:get_task_status).and_return(api_response_lowercase_success)
      end

      it 'still works with lowercase completed status for backward compatibility' do
        expect { job.send(:poll_for_completion) }.not_to raise_error
        expect(job.instance_variable_get(:@task_data)).to eq(api_response_lowercase_success)
      end
    end
  end

  describe '#calculate_polling_interval' do
    subject(:job) { described_class.new }

    it 'implements exponential backoff' do
      # First attempt: 5 seconds (+ jitter)
      interval1 = job.send(:calculate_polling_interval, 1)
      expect(interval1).to be_between(5, 6.5)

      # Second attempt: 10 seconds (+ jitter)
      interval2 = job.send(:calculate_polling_interval, 2)
      expect(interval2).to be_between(10, 13)

      # Third attempt: 20 seconds (+ jitter)
      interval3 = job.send(:calculate_polling_interval, 3)
      expect(interval3).to be_between(20, 26)

      # Fourth attempt: should cap at MAX_POLLING_INTERVAL (30 seconds + jitter)
      interval4 = job.send(:calculate_polling_interval, 4)
      expect(interval4).to be_between(30, 39)

      # Fifth attempt: should still cap at MAX_POLLING_INTERVAL
      interval5 = job.send(:calculate_polling_interval, 5)
      expect(interval5).to be_between(30, 39)
    end
  end
end
