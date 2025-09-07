require 'rails_helper'

RSpec.describe KieService do
  before do
    # CI環境でAPI KEYが設定されていない場合のためにスタブ化
    ENV['KIE_AI_API_KEY'] ||= 'test_api_key'
  end

  let(:service) { described_class.new }

  describe '#initialize' do
    context 'when API key is set' do
      it 'initializes successfully' do
        expect { service }.not_to raise_error
      end
    end

    context 'when API key is not set' do
      it 'raises an error' do
        original_key = ENV['KIE_AI_API_KEY']
        ENV.delete('KIE_AI_API_KEY')

        expect { described_class.new }.to raise_error(Kie::Errors::AuthenticationError, 'KIE_AI_API_KEY is not set')

        ENV['KIE_AI_API_KEY'] = original_key
      end
    end
  end

  describe '#generate_music', vcr: { cassette_name: 'kie_service/generate_music' } do
    let(:prompt) { 'Relaxing lo-fi hip hop beat with soft piano' }

    it 'sends a request to generate music and returns task_id' do
      result = service.generate_music(prompt: prompt)
      expect(result).to be_a(String)
      expect(result).to match(/^[a-f0-9-]+$/)
    end

    context 'when prompt is blank' do
      it 'raises an ArgumentError' do
        expect { service.generate_music(prompt: '') }.to raise_error(ArgumentError, 'Prompt cannot be blank')
      end
    end

    context 'when prompt is too long' do
      let(:long_prompt) { 'a' * 3001 }

      it 'raises an ArgumentError' do
        expect { service.generate_music(prompt: long_prompt) }.to raise_error(ArgumentError, 'Prompt is too long (maximum 3000 characters)')
      end
    end
  end

  describe '#get_task_status' do
    context 'with valid task_id', vcr: { cassette_name: 'kie_service/get_task_status_success' } do
      # First generate a task to get a valid task_id
      let(:task_id) do
        VCR.use_cassette('kie_service/generate_for_status_check') do
          service.generate_music(prompt: 'Test beat for status check')
        end
      end

      it 'retrieves task status' do
        # Wait a bit for the task to process (in real scenario)
        sleep 2 if VCR.current_cassette.recording?

        result = service.get_task_status(task_id)
        expect(result).to be_a(Hash)
        expect(result).to have_key('taskId')
      end

      context 'in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
          allow(Rails.logger).to receive(:debug)
        end

        it 'logs the full response in debug level' do
          expect(Rails.logger).to receive(:debug).with(/KIE API Response for task/)
          service.get_task_status(task_id)
        end
      end

      context 'in production environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
          allow(Rails.logger).to receive(:debug)
        end

        it 'does not log the full response' do
          expect(Rails.logger).not_to receive(:debug)
          service.get_task_status(task_id)
        end
      end
    end

    context 'when task_id is blank' do
      it 'raises an ArgumentError' do
        expect { service.get_task_status('') }.to raise_error(ArgumentError, 'Task ID cannot be blank')
      end
    end

    context 'with invalid task_id', vcr: { cassette_name: 'kie_service/get_task_status_not_found' } do
      let(:invalid_task_id) { 'invalid-task-id-12345' }

      it 'returns nil or error data' do
        result = service.get_task_status(invalid_task_id)
        expect(result).to be_nil.or be_a(Hash)
      end
    end

    context 'response validation' do
      let(:task_id) { 'test-task-id' }

      before do
        allow(Rails.logger).to receive(:warn)
      end

      context 'when response is missing required fields' do
        it 'logs warning when status field is missing' do
          allow(service).to receive(:with_retry).and_return({ 'data' => { 'taskId' => task_id } })

          expect(Rails.logger).to receive(:warn).with(/Missing required field: status/)
          service.get_task_status(task_id)
        end

        it 'logs warning when taskId field is missing' do
          allow(service).to receive(:with_retry).and_return({ 'data' => { 'status' => 'processing' } })

          expect(Rails.logger).to receive(:warn).with(/Missing required field: taskId/)
          service.get_task_status(task_id)
        end
      end

      context 'when response has unexpected format' do
        it 'logs warning for unexpected response structure' do
          allow(service).to receive(:with_retry).and_return({ 'data' => 'unexpected_string_response' })

          expect(Rails.logger).to receive(:warn).with(/Unexpected response format/)
          service.get_task_status(task_id)
        end
      end

      context 'when response has all required fields' do
        it 'does not log warning for valid response' do
          allow(service).to receive(:with_retry).and_return({
            'data' => {
              'taskId' => task_id,
              'status' => 'completed',
              'output' => { 'audio_url' => 'https://example.com/audio.mp3' }
            }
          })

          expect(Rails.logger).not_to receive(:warn)
          service.get_task_status(task_id)
        end
      end
    end
  end

  describe '#download_audio' do
    let(:audio_url) { 'https://example.com/test_audio.mp3' }
    let(:file_path) { Rails.root.join('tmp', 'test_downloads', 'test_audio.mp3') }

    after do
      FileUtils.rm_rf(Rails.root.join('tmp', 'test_downloads'))
    end

    context 'with valid URL', vcr: { cassette_name: 'kie_service/download_audio_success' } do
      # For testing, we'll use a real MP3 URL or mock it
      let(:audio_url) { 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' }

      it 'downloads audio file' do
        result = service.download_audio(audio_url, file_path)
        expect(result).to eq(file_path)
        expect(File.exist?(file_path)).to be true
      end
    end

    context 'when URL is blank' do
      it 'raises an ArgumentError' do
        expect { service.download_audio('', file_path) }.to raise_error(ArgumentError, 'Audio URL cannot be blank')
      end
    end

    context 'when file_path is blank' do
      it 'raises an ArgumentError' do
        expect { service.download_audio(audio_url, '') }.to raise_error(ArgumentError, 'File path cannot be blank')
      end
    end
  end

  describe '#with_retry' do
    it 'retries on NetworkError' do
      call_count = 0
      expect(service).to receive(:sleep).with(1).once

      result = service.send(:with_retry, max_retries: 2) do
        call_count += 1
        raise Kie::Errors::NetworkError if call_count < 2
        'success'
      end

      expect(result).to eq('success')
      expect(call_count).to eq(2)
    end

    it 'retries on RateLimitError with exponential backoff' do
      expect(service).to receive(:sleep).with(1).ordered
      expect(service).to receive(:sleep).with(2).ordered

      expect do
        service.send(:with_retry, max_retries: 3) do
          raise Kie::Errors::RateLimitError
        end
      end.to raise_error(Kie::Errors::RateLimitError)
    end

    it 'does not retry on non-retryable errors' do
      expect(service).not_to receive(:sleep)

      expect do
        service.send(:with_retry) do
          raise Kie::Errors::AuthenticationError
        end
      end.to raise_error(Kie::Errors::AuthenticationError)
    end
  end
end
