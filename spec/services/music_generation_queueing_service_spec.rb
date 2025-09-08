require 'rails_helper'

RSpec.describe MusicGenerationQueueingService do
  let(:content) { create(:content, duration: 600) } # 10 minutes
  let(:service) { described_class.new(content) }

  describe '.calculate_music_generation_count' do
    it 'calculates the correct number of music generations needed' do
      # Each music generation creates 2 tracks (240 seconds each = 480 seconds total)
      # 600 seconds / 480 seconds = 1.25 -> 2 generations needed
      expect(described_class.calculate_music_generation_count(600)).to eq(2)
    end

    it 'rounds up when duration is not evenly divisible' do
      expect(described_class.calculate_music_generation_count(500)).to eq(2)
    end

    it 'returns 1 for short durations' do
      expect(described_class.calculate_music_generation_count(100)).to eq(1)
    end

    it 'handles large durations' do
      # 3600 seconds / 480 seconds = 7.5 -> 8 generations
      expect(described_class.calculate_music_generation_count(3600)).to eq(8)
    end
  end

  describe '#queue_music_generations!' do
    it 'creates the correct number of MusicGeneration records' do
      expect {
        service.queue_music_generations!
      }.to change(MusicGeneration, :count).by(2)
    end

    it 'creates music generations with correct attributes' do
      service.queue_music_generations!

      music_generations = content.music_generations.order(:created_at)

      music_generations.each do |mg|
        expect(mg.status).to eq('pending')
        expect(mg.prompt).to eq(content.audio_prompt)
        expect(mg.generation_model).to eq('V4_5PLUS')
        expect(mg.task_id).to be_present
      end
    end

    it 'enqueues GenerateMusicGenerationJob for each music generation' do
      expect {
        service.queue_music_generations!
      }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(2).times
    end

    it 'returns the created music generations' do
      result = service.queue_music_generations!
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.all? { |mg| mg.is_a?(MusicGeneration) }).to be true
    end

    context 'when music generations already exist' do
      before do
        create(:music_generation, content: content)
      end

      it 'creates additional music generations to meet the requirement' do
        expect {
          service.queue_music_generations!
        }.to change(MusicGeneration, :count).by(1)
      end
    end

    context 'when sufficient music generations already exist' do
      before do
        create_list(:music_generation, 2, content: content)
      end

      it 'does not create additional music generations' do
        expect {
          service.queue_music_generations!
        }.not_to change(MusicGeneration, :count)
      end

      it 'returns an empty array' do
        result = service.queue_music_generations!
        expect(result).to eq([])
      end
    end
  end

  describe '#required_music_generation_count' do
    it 'returns the calculated count based on content duration' do
      expect(service.required_music_generation_count).to eq(2)
    end
  end

  describe '#existing_music_generation_count' do
    it 'returns 0 when no music generations exist' do
      expect(service.existing_music_generation_count).to eq(0)
    end

    it 'returns the count of existing music generations' do
      create_list(:music_generation, 3, content: content)
      expect(service.existing_music_generation_count).to eq(3)
    end
  end
end
