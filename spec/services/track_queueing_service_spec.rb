require 'rails_helper'

RSpec.describe TrackQueueingService do
  include ActiveJob::TestHelper
  let(:content) { create(:content, duration_min: 10, audio_prompt: 'Custom lo-fi beat') }

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

    it 'calculates correct track count for long duration content' do
      # 120分: (120 / 6) + 5 = 20 + 5 = 25
      expect(described_class.calculate_track_count(120)).to eq(25)
      # 180分: (180 / 6) + 5 = 30 + 5 = 35
      expect(described_class.calculate_track_count(180)).to eq(35)
      # 300分: (300 / 6) + 5 = 50 + 5 = 55
      expect(described_class.calculate_track_count(300)).to eq(55)
      # 600分: (600 / 6) + 5 = 100 + 5 = 105
      expect(described_class.calculate_track_count(600)).to eq(105)
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
      it 'creates the correct number of music generations' do
        # For duration 10: 7 tracks needed, each MusicGeneration produces 2 tracks
        # So we need ceil(7/2) = 4 MusicGeneration
        expect {
          service.queue_tracks!
        }.to change { content.music_generations.count }.by(4)
      end

      it 'creates music generations with pending status' do
        service.queue_tracks!

        expect(content.music_generations.all?(&:pending?)).to be true
      end

      it 'enqueues GenerateMusicJob for each music generation' do
        expect {
          service.queue_tracks!
        }.to have_enqueued_job(GenerateMusicJob).exactly(4).times
      end

      it 'returns the created music generations' do
        music_generations = service.queue_tracks!

        expect(music_generations).to all(be_a(MusicGeneration))
        expect(music_generations.count).to eq(4)
        expect(music_generations).to all(have_attributes(
          content: content,
          status: 'pending',
          prompt: content.audio_prompt,
          generation_model: 'V4_5PLUS'
        ))
      end

      it 'logs the operation' do
        allow(Rails.logger).to receive(:info)

        service.queue_tracks!

        expect(Rails.logger).to have_received(:info).with("Queued 4 music generations for Content ##{content.id} (expecting 7 tracks)")
      end

      context 'with different durations' do
        it 'creates correct number of music generations for 6 duration' do
          content.update!(duration_min: 6)
          # 6 tracks needed, ceil(6/2) = 3 MusicGeneration
          expect {
            service.queue_tracks!
          }.to change { content.music_generations.count }.by(3)
        end

        it 'creates correct number of music generations for 120 duration' do
          content.update!(duration_min: 120)
          # 25 tracks needed, ceil(25/2) = 13 MusicGeneration
          expect {
            service.queue_tracks!
          }.to change { content.music_generations.count }.by(13)
        end
      end
    end

    context 'when validation fails' do
      context 'when duration is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test') }
        let(:service) { described_class.new(invalid_content) }

        it 'raises ValidationError' do
          expect { service.queue_tracks! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content duration is required'
          )
        end
      end

      context 'when audio_prompt is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration_min: 10, audio_prompt: nil) }
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

      context 'when long duration content exceeds track limit' do
        let(:long_content) { create(:content, duration_min: 600, audio_prompt: 'Long music') }
        let(:service) { described_class.new(long_content) }

        it 'raises ValidationError for 600 minutes content' do
          # 600分の場合、105トラック必要で上限100を超える
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
      invalid_content = Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test')
      service = described_class.new(invalid_content)

      expect { service.send(:validate!) }.to raise_error(
        TrackQueueingService::ValidationError,
        'Content duration is required'
      )
    end

    it 'validates audio_prompt presence' do
      invalid_content = Content.new(theme: 'test', duration_min: 10, audio_prompt: nil)
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

  describe '#queue_single_track!' do
    let(:service) { described_class.new(content) }

    context 'when content is valid' do
      it 'does not immediately create tracks' do
        expect {
          service.queue_single_track!
        }.not_to change { content.tracks.count }
      end

      it 'creates a MusicGeneration' do
        expect {
          service.queue_single_track!
        }.to change { content.music_generations.count }.by(1)

        music_generation = content.music_generations.last
        expect(music_generation.prompt).to eq(content.audio_prompt)
        expect(music_generation.generation_model).to eq("V4_5PLUS")
        expect(music_generation.status.pending?).to be true
      end

      it 'enqueues GenerateMusicJob for the music generation' do
        expect {
          service.queue_single_track!
        }.to have_enqueued_job(GenerateMusicJob).once
      end

      it 'returns the created music generation' do
        music_generation = service.queue_single_track!

        expect(music_generation).to be_a(MusicGeneration)
        expect(music_generation).to have_attributes(
          content: content,
          status: 'pending',
          prompt: content.audio_prompt,
          generation_model: "V4_5PLUS"
        )
      end

      it 'logs the operation' do
        allow(Rails.logger).to receive(:info)

        service.queue_single_track!

        expect(Rails.logger).to have_received(:info).with("Queued MusicGeneration ##{MusicGeneration.last.id} for Content ##{content.id}")
      end
    end

    context 'when validation fails' do
      context 'when duration is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test') }
        let(:service) { described_class.new(invalid_content) }

        it 'raises ValidationError' do
          expect { service.queue_single_track! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content duration is required'
          )
        end
      end

      context 'when audio_prompt is missing' do
        let(:invalid_content) { Content.new(theme: 'test', duration_min: 10, audio_prompt: nil) }
        let(:service) { described_class.new(invalid_content) }

        it 'raises ValidationError' do
          expect { service.queue_single_track! }.to raise_error(
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
          expect { service.queue_single_track! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content already has tracks being generated'
          )
        end
      end

      context 'when content would exceed track limit' do
        before do
          create_list(:track, 100, content: content)
        end

        it 'raises ValidationError' do
          expect { service.queue_single_track! }.to raise_error(
            TrackQueueingService::ValidationError,
            'Content would exceed maximum track limit (100)'
          )
        end
      end

      context 'when content has exactly 99 tracks' do
        before do
          create_list(:track, 99, content: content)
        end

        it 'allows one more music generation' do
          expect {
            service.queue_single_track!
          }.to change { content.music_generations.count }.by(1)
        end
      end
    end
  end
end
