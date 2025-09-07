require 'rails_helper'

RSpec.describe Track, type: :model do
  describe 'associations' do
    it { should belong_to(:content) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:status) }
  end

  describe 'enumerize' do
    it { should enumerize(:status).in(:pending, :processing, :completed, :failed).with_default(:pending).with_predicates(true) }
  end

  describe 'scopes' do
    describe '.recent' do
      let!(:old_track) { create(:track, created_at: 2.days.ago) }
      let!(:new_track) { create(:track, created_at: 1.day.ago) }

      it 'returns tracks ordered by created_at desc' do
        expect(Track.recent).to eq([ new_track, old_track ])
      end
    end

    describe '.by_status' do
      let!(:pending_track) { create(:track, status: :pending) }
      let!(:completed_track) { create(:track, status: :completed) }

      it 'returns tracks with specified status' do
        expect(Track.by_status(:pending)).to include(pending_track)
        expect(Track.by_status(:pending)).not_to include(completed_track)
      end
    end
  end

  describe 'audio attachment' do
    let(:track) { create(:track) }
    let(:mp3_file) { File.open(Rails.root.join('spec/fixtures/files/sample.mp3')) }

    after do
      mp3_file.close if mp3_file && !mp3_file.closed?
    end

    it 'can attach an audio file' do
      track.audio = mp3_file
      expect { track.save! }.not_to raise_error
      expect(track.audio).to be_present
    end

    it 'stores audio data in audio_data column' do
      track.audio = mp3_file
      track.save!

      expect(track.audio_data).to be_present
      expect(track.audio_data).to be_a(Hash)
    end

    it 'can retrieve the attached audio file' do
      track.audio = mp3_file
      track.save!

      reloaded_track = Track.find(track.id)
      expect(reloaded_track.audio).to be_present
      expect(reloaded_track.audio.original_filename).to eq('sample.mp3')
    end

    it 'can delete the attached audio file' do
      track.audio = mp3_file
      track.save!

      track.audio = nil
      track.save!

      expect(track.audio).to be_nil
      expect(track.audio_data).to be_nil
    end
  end
end
