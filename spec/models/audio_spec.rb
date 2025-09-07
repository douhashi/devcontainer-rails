require 'rails_helper'

RSpec.describe Audio, type: :model do
  describe 'associations' do
    it 'belongs to content' do
      expect(Audio.reflect_on_association(:content).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:content) { create(:content) }

    it 'validates presence of content' do
      audio = Audio.new(status: :pending)
      expect(audio.valid?).to be false
      expect(audio.errors[:content]).to include("must exist")
    end

    it 'is valid with content and status' do
      audio = Audio.new(content: content, status: :pending)
      expect(audio.valid?).to be true
    end
  end

  describe 'enumerize status' do
    let(:content) { create(:content) }

    it 'allows valid status values' do
      %i[pending processing completed failed].each do |status|
        audio = Audio.new(content: content, status: status)
        expect(audio.status).to eq(status.to_s)
      end
    end

    it 'has default status as pending' do
      audio = Audio.new(content: content)
      expect(audio.status).to eq('pending')
    end
  end

  describe 'scopes' do
    let(:content) { create(:content) }
    let!(:pending_audio) { create(:audio, content: content, status: :pending) }
    let!(:processing_audio) { create(:audio, content: content, status: :processing) }
    let!(:completed_audio) { create(:audio, content: content, status: :completed) }
    let!(:failed_audio) { create(:audio, content: content, status: :failed) }

    describe '.pending' do
      it 'returns only pending audios' do
        expect(Audio.pending).to eq([ pending_audio ])
      end
    end

    describe '.processing' do
      it 'returns only processing audios' do
        expect(Audio.processing).to eq([ processing_audio ])
      end
    end

    describe '.completed' do
      it 'returns only completed audios' do
        expect(Audio.completed).to eq([ completed_audio ])
      end
    end

    describe '.failed' do
      it 'returns only failed audios' do
        expect(Audio.failed).to eq([ failed_audio ])
      end
    end
  end

  describe 'predicates' do
    let(:content) { create(:content) }

    it 'returns true for corresponding status predicates' do
      audio = create(:audio, content: content, status: :pending)
      expect(audio.pending?).to be true
      expect(audio.processing?).to be false
      expect(audio.completed?).to be false
      expect(audio.failed?).to be false
    end
  end

  describe 'metadata handling' do
    let(:content) { create(:content) }
    let(:metadata) { { selected_tracks: [ 1, 2, 3 ], total_duration: 180 } }
    let(:audio) { create(:audio, content: content, metadata: metadata) }

    it 'stores and retrieves metadata as JSON' do
      expect(audio.metadata).to be_a(Hash)
      expect(audio.metadata['selected_tracks']).to eq([ 1, 2, 3 ])
      expect(audio.metadata['total_duration']).to eq(180)
    end
  end
end
