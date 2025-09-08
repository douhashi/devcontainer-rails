require 'rails_helper'

RSpec.describe MusicGeneration, type: :model do
  describe 'associations' do
    it { should belong_to(:content) }
    it { should have_many(:tracks).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:task_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:prompt) }
    it { should validate_presence_of(:generation_model) }
  end

  describe 'status enum' do
    it 'has correct status values' do
      expect(MusicGeneration.new).to enumerize(:status).in(:pending, :processing, :completed, :failed)
    end

    it 'sets default status to pending' do
      music_generation = MusicGeneration.new
      expect(music_generation.status).to eq('pending')
    end
  end

  describe 'scopes' do
    describe '.pending' do
      it 'returns only pending music generations' do
        pending_generation = create(:music_generation, status: :pending)
        completed_generation = create(:music_generation, status: :completed)

        expect(MusicGeneration.pending).to include(pending_generation)
        expect(MusicGeneration.pending).not_to include(completed_generation)
      end
    end

    describe '.completed' do
      it 'returns only completed music generations' do
        pending_generation = create(:music_generation, status: :pending)
        completed_generation = create(:music_generation, status: :completed)

        expect(MusicGeneration.completed).to include(completed_generation)
        expect(MusicGeneration.completed).not_to include(pending_generation)
      end
    end
  end

  describe '#complete!' do
    let(:music_generation) { create(:music_generation, status: :processing) }

    it 'updates status to completed' do
      music_generation.complete!
      expect(music_generation.reload.status).to eq('completed')
    end
  end

  describe '#fail!' do
    let(:music_generation) { create(:music_generation, status: :processing) }

    it 'updates status to failed' do
      music_generation.fail!
      expect(music_generation.reload.status).to eq('failed')
    end
  end

  describe '#processing!' do
    let(:music_generation) { create(:music_generation, status: :pending) }

    it 'updates status to processing' do
      music_generation.processing!
      expect(music_generation.reload.status).to eq('processing')
    end
  end
end
