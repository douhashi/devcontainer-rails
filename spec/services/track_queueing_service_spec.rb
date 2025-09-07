require 'rails_helper'

RSpec.describe TrackQueueingService do
  include ActiveJob::TestHelper
  let(:content) { create(:content, duration: 10, audio_prompt: 'Custom lo-fi beat') }

  describe '.calculate_track_count' do
    it 'calculates correct track count based on duration formula' do
      # (duration / (3*2)) + 5 = (10 / 6) + 5 = 1.67 + 5 = 6.67 => 7
      expect(described_class.calculate_track_count(10)).to eq(7)
    end

    it 'handles edge cases correctly' do
      expect(described_class.calculate_track_count(0)).to eq(5)
      expect(described_class.calculate_track_count(6)).to eq(6)
      expect(described_class.calculate_track_count(12)).to eq(7)
      expect(described_class.calculate_track_count(18)).to eq(8)
    end
  end

  describe '#initialize' do
    it 'initializes with content' do
      service = described_class.new(content)
      expect(service.content).to eq(content)
    end
  end

  describe '#queue_tracks!' do
    let(:service) { described_class.new(content) }

    context 'when content is valid' do
      it 'creates the correct number of tracks' do
        expect {
          service.queue_tracks!
        }.to change { content.tracks.count }.by(7)
      end

      it 'creates tracks with pending status' do
        service.queue_tracks!

        expect(content.tracks.all?(&:pending?)).to be true
      end

      it 'enqueues GenerateTrackJob for each track' do
        expect {
          service.queue_tracks!
        }.to have_enqueued_job(GenerateTrackJob).exactly(7).times
      end

      it 'returns the created tracks' do
        tracks = service.queue_tracks!

        expect(tracks).to all(be_a(Track))
        expect(tracks.count).to eq(7)
        expect(tracks).to all(have_attributes(content: content, status: 'pending'))
      end

      it 'logs the operation' do
        allow(Rails.logger).to receive(:info)

        service.queue_tracks!

        expect(Rails.logger).to have_received(:info).with("Queued 7 tracks for Content ##{content.id}")
      end
    end

    context 'when validation fails' do
      context 'when duration is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration: nil, audio_prompt: 'test') }
        let(:service) { described_class.new(invalid_content) }

        it 'raises ValidationError' do
          expect { service.queue_tracks! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content duration is required'
          )
        end
      end

      context 'when audio_prompt is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration: 10, audio_prompt: nil) }
        let(:service) { described_class.new(invalid_content) }

        it 'raises ValidationError' do
          expect { service.queue_tracks! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content audio_prompt is required'
          )
        end
      end

      context 'when content already has processing tracks' do
        before do
          create(:track, content: content, status: :processing)
        end

        it 'raises ValidationError' do
          expect { service.queue_tracks! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content already has tracks being generated'
          )
        end
      end

      context 'when content would exceed track limit' do
        before do
          create_list(:track, 95, content: content)
        end

        it 'raises ValidationError' do
          expect { service.queue_tracks! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content would exceed maximum track limit (100)'
          )
        end
      end
    end
  end

  describe '#validate!' do
    let(:service) { described_class.new(content) }

    it 'does not raise error for valid content' do
      expect { service.send(:validate!) }.not_to raise_error
    end

    it 'validates duration presence' do
      invalid_content = Content.new(theme: 'test', duration: nil, audio_prompt: 'test')
      service = described_class.new(invalid_content)

      expect { service.send(:validate!) }.to raise_error(
        TrackQueueingService::ValidationError,
        'Content duration is required'
      )
    end

    it 'validates audio_prompt presence' do
      invalid_content = Content.new(theme: 'test', duration: 10, audio_prompt: nil)
      service = described_class.new(invalid_content)

      expect { service.send(:validate!) }.to raise_error(
        TrackQueueingService::ValidationError,
        'Content audio_prompt is required'
      )
    end

    it 'validates no processing tracks exist' do
      create(:track, content: content, status: :processing)

      expect { service.send(:validate!) }.to raise_error(
        TrackQueueingService::ValidationError,
        'Content already has tracks being generated'
      )
    end

    it 'validates track limit would not be exceeded' do
      create_list(:track, 95, content: content)

      expect { service.send(:validate!) }.to raise_error(
        TrackQueueingService::ValidationError,
        'Content would exceed maximum track limit (100)'
      )
    end
  end

  describe '#processing_tracks?' do
    let(:service) { described_class.new(content) }

    it 'returns false when no processing tracks exist' do
      create(:track, content: content, status: :pending)
      create(:track, content: content, status: :completed)

      expect(service.send(:processing_tracks?)).to be false
    end

    it 'returns true when processing tracks exist' do
      create(:track, content: content, status: :processing)

      expect(service.send(:processing_tracks?)).to be true
    end
  end

  describe '#would_exceed_limit?' do
    let(:service) { described_class.new(content) }

    it 'returns false when within limit' do
      create_list(:track, 90, content: content)

      expect(service.send(:would_exceed_limit?, 7)).to be false
    end

    it 'returns true when would exceed limit' do
      create_list(:track, 95, content: content)

      expect(service.send(:would_exceed_limit?, 7)).to be true
    end

    it 'handles exact limit correctly' do
      create_list(:track, 93, content: content)

      expect(service.send(:would_exceed_limit?, 7)).to be false
      expect(service.send(:would_exceed_limit?, 8)).to be true
    end
  end
end
