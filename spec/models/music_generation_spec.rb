require 'rails_helper'

RSpec.describe MusicGeneration, type: :model do
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
