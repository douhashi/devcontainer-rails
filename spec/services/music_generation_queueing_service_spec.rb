require 'rails_helper'

RSpec.describe MusicGenerationQueueingService do
  let(:content) { create(:content, duration_min: 10) } # 10 minutes
  let(:service) { described_class.new(content) }

  describe '.calculate_music_generation_count' do
    it 'calculates the correct number of music generations needed using new formula' do
      # New formula: (duration_min / (3*2)) + 5
      # 10 minutes: (10 / 6) + 5 = 1.67 + 5 = 6.67 -> 7 generations needed
      expect(described_class.calculate_music_generation_count(10)).to eq(7)
    end

    it 'returns correct count for 6 minutes (edge case)' do
      # 6 minutes: (6 / 6) + 5 = 1 + 5 = 6 generations needed
      expect(described_class.calculate_music_generation_count(6)).to eq(6)
    end

    it 'returns correct count for 60 minutes' do
      # 60 minutes: (60 / 6) + 5 = 10 + 5 = 15 generations needed
      expect(described_class.calculate_music_generation_count(60)).to eq(15)
    end

    it 'returns correct count for 120 minutes' do
      # 120 minutes: (120 / 6) + 5 = 20 + 5 = 25 generations needed
      expect(described_class.calculate_music_generation_count(120)).to eq(25)
    end

    it 'handles small durations with buffer' do
      # 1 minute: (1 / 6) + 5 = 0.17 + 5 = 5.17 -> 6 generations needed (minimum with buffer)
      expect(described_class.calculate_music_generation_count(1)).to eq(6)
    end

    it 'returns 0 for nil duration' do
      expect(described_class.calculate_music_generation_count(nil)).to eq(0)
    end

    it 'returns 0 for zero or negative duration' do
      expect(described_class.calculate_music_generation_count(0)).to eq(0)
      expect(described_class.calculate_music_generation_count(-5)).to eq(0)
    end
  end

  describe '#queue_music_generations!' do
    it 'creates the correct number of MusicGeneration records' do
      expect {
        service.queue_music_generations!
      }.to change(MusicGeneration, :count).by(7)
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
      }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(7).times
    end

    it 'returns the created music generations' do
      result = service.queue_music_generations!
      expect(result).to be_an(Array)
      expect(result.size).to eq(7)
      expect(result.all? { |mg| mg.is_a?(MusicGeneration) }).to be true
    end

    context 'when music generations already exist' do
      before do
        create(:music_generation, content: content)
      end

      it 'creates additional music generations to meet the requirement' do
        expect {
          service.queue_music_generations!
        }.to change(MusicGeneration, :count).by(6)
      end
    end

    context 'when sufficient music generations already exist' do
      before do
        create_list(:music_generation, 7, content: content)
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
      expect(service.required_music_generation_count).to eq(7)
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

  describe '#queue_single_generation!' do
    it 'creates exactly one MusicGeneration record' do
      expect {
        service.queue_single_generation!
      }.to change(MusicGeneration, :count).by(1)
    end

    it 'creates music generation with correct attributes' do
      music_generation = service.queue_single_generation!

      expect(music_generation.status).to eq('pending')
      expect(music_generation.prompt).to eq(content.audio_prompt)
      expect(music_generation.generation_model).to eq('V4_5PLUS')
      expect(music_generation.task_id).to be_present
    end

    it 'enqueues GenerateMusicGenerationJob' do
      expect {
        service.queue_single_generation!
      }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(:once)
    end

    it 'returns the created music generation' do
      result = service.queue_single_generation!
      expect(result).to be_a(MusicGeneration)
      expect(result).to be_persisted
    end

    context 'when music generations already exist' do
      before do
        create_list(:music_generation, 10, content: content)
      end

      it 'still creates a new music generation' do
        expect {
          service.queue_single_generation!
        }.to change(MusicGeneration, :count).by(1)
      end
    end

    context 'when tracks already exist' do
      before do
        create_list(:track, 100, content: content)
      end

      it 'still creates a new music generation' do
        expect {
          service.queue_single_generation!
        }.to change(MusicGeneration, :count).by(1)
      end
    end
  end

  describe '#queue_bulk_generation!' do
    it 'creates the specified number of MusicGeneration records' do
      expect {
        service.queue_bulk_generation!(5)
      }.to change(MusicGeneration, :count).by(5)
    end

    it 'defaults to calculated recommended count when no count is specified' do
      expect {
        service.queue_bulk_generation!
      }.to change(MusicGeneration, :count).by(7) # 10 minutes = 7 generations with new formula
    end

    it 'creates music generations with correct attributes' do
      music_generations = service.queue_bulk_generation!(3)

      expect(music_generations.size).to eq(3)
      music_generations.each do |mg|
        expect(mg.status).to eq('pending')
        expect(mg.prompt).to eq(content.audio_prompt)
        expect(mg.generation_model).to eq('V4_5PLUS')
        expect(mg.task_id).to be_present
      end
    end

    it 'enqueues GenerateMusicGenerationJob for each music generation' do
      expect {
        service.queue_bulk_generation!(3)
      }.to have_enqueued_job(GenerateMusicGenerationJob).exactly(3).times
    end

    it 'returns an array of created music generations' do
      result = service.queue_bulk_generation!(3)
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result.all? { |mg| mg.is_a?(MusicGeneration) }).to be true
      expect(result.all?(&:persisted?)).to be true
    end

    context 'when music generations already exist' do
      before do
        create_list(:music_generation, 10, content: content)
      end

      it 'still creates the specified number of new music generations' do
        expect {
          service.queue_bulk_generation!(5)
        }.to change(MusicGeneration, :count).by(5)
      end
    end

    context 'when tracks already exist' do
      before do
        create_list(:track, 100, content: content)
      end

      it 'still creates the specified number of new music generations' do
        expect {
          service.queue_bulk_generation!(5)
        }.to change(MusicGeneration, :count).by(5)
      end
    end
  end
end
