require 'rails_helper'

RSpec.describe AudioAnalysisService do
  describe '#analyze_duration' do
    let(:service) { AudioAnalysisService.new }

    context 'with valid audio file' do
      let(:audio_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }

      it 'returns duration in seconds' do
        allow(service).to receive(:execute_ffprobe).and_return("180.123\n")

        duration = service.analyze_duration(audio_path)

        expect(duration).to eq(180)
      end

      it 'handles decimal durations by rounding down' do
        allow(service).to receive(:execute_ffprobe).and_return("185.789\n")

        duration = service.analyze_duration(audio_path)

        expect(duration).to eq(185)
      end
    end

    context 'with invalid file path' do
      let(:invalid_path) { '/nonexistent/file.mp3' }

      it 'returns default duration when file does not exist' do
        allow(service).to receive(:execute_ffprobe).and_raise(StandardError.new('File not found'))
        allow(Rails.logger).to receive(:error)

        duration = service.analyze_duration(invalid_path)

        expect(duration).to eq(180) # Default 3 minutes
        expect(Rails.logger).to have_received(:error).with(/Failed to analyze audio duration/)
      end
    end

    context 'with ffprobe command failure' do
      let(:audio_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }

      it 'returns default duration when command fails' do
        allow(service).to receive(:execute_ffprobe).and_raise(StandardError.new('ffprobe error'))
        allow(Rails.logger).to receive(:error)

        duration = service.analyze_duration(audio_path)

        expect(duration).to eq(180) # Default 3 minutes
        expect(Rails.logger).to have_received(:error).with(/Failed to analyze audio duration/)
      end
    end

    context 'with invalid ffprobe output' do
      let(:audio_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }

      it 'returns default duration when output is not a number' do
        allow(service).to receive(:execute_ffprobe).and_return("N/A\n")
        allow(Rails.logger).to receive(:error)

        duration = service.analyze_duration(audio_path)

        expect(duration).to eq(180) # Default 3 minutes
        expect(Rails.logger).to have_received(:error).with(/Failed to analyze audio duration/)
      end
    end
  end

  describe '#execute_ffprobe' do
    let(:service) { AudioAnalysisService.new }
    let(:audio_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }

    it 'executes ffprobe command with correct arguments' do
      expected_command = [
        'ffprobe',
        '-v', 'quiet',
        '-show_entries', 'format=duration',
        '-of', 'csv=p=0',
        audio_path.to_s
      ]

      allow(Open3).to receive(:capture3).with(*expected_command, timeout: 5).and_return([ '180.123', '', double(success?: true) ])

      result = service.send(:execute_ffprobe, audio_path)

      expect(result).to eq('180.123')
      expect(Open3).to have_received(:capture3).with(*expected_command, timeout: 5)
    end

    it 'raises error when command fails' do
      allow(Open3).to receive(:capture3).and_return([ '', 'error output', double(success?: false) ])

      expect {
        service.send(:execute_ffprobe, audio_path)
      }.to raise_error(StandardError, /ffprobe command failed/)
    end

    it 'raises error on timeout' do
      allow(Open3).to receive(:capture3).and_raise(Timeout::Error)

      expect {
        service.send(:execute_ffprobe, audio_path)
      }.to raise_error(StandardError, /ffprobe command timed out/)
    end
  end
end
