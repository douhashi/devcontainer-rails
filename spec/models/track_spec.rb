require 'rails_helper'

RSpec.describe Track, type: :model do
  describe 'associations' do
    it { should belong_to(:content) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:status) }

    describe 'duration' do
      let(:track) { build(:track, content: create(:content)) }

      it 'validates numericality of duration' do
        track.duration = 'invalid'
        expect(track).to be_invalid
        expect(track.errors[:duration]).to include('is not a number')
      end

      it 'allows positive integers' do
        track.duration = 180
        expect(track).to be_valid
      end

      it 'allows nil values' do
        track.duration = nil
        expect(track).to be_valid
      end

      it 'does not allow zero or negative values' do
        track.duration = 0
        expect(track).to be_invalid
        expect(track.errors[:duration]).to include('must be greater than 0')

        track.duration = -10
        expect(track).to be_invalid
        expect(track.errors[:duration]).to include('must be greater than 0')
      end
    end
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

  describe '#generate_audio!' do
    let(:track) { create(:track, status: :pending) }

    it 'enqueues GenerateTrackJob' do
      expect {
        track.generate_audio!
      }.to have_enqueued_job(GenerateTrackJob).with(track.id)
    end

    it 'does not enqueue job if status is not pending' do
      allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")
      track.update!(status: :processing)

      expect {
        track.generate_audio!
      }.not_to have_enqueued_job(GenerateTrackJob)
    end

    it 'returns true when job is enqueued' do
      expect(track.generate_audio!).to be true
    end

    it 'returns false when job is not enqueued' do
      allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")
      track.update!(status: :completed)
      expect(track.generate_audio!).to be false
    end
  end

  describe '#formatted_duration' do
    let(:track) { build(:track) }

    context 'when duration is nil' do
      it 'returns "未取得"' do
        track.duration = nil
        expect(track.formatted_duration).to eq('未取得')
      end
    end

    context 'when duration is present' do
      it 'formats duration as "M:SS" for durations under an hour' do
        track.duration = 185
        expect(track.formatted_duration).to eq('3:05')
      end

      it 'formats duration as "H:MM:SS" for durations over an hour' do
        track.duration = 3665
        expect(track.formatted_duration).to eq('1:01:05')
      end

      it 'handles zero correctly' do
        track.duration = 0
        expect(track.formatted_duration).to eq('0:00')
      end

      it 'handles single digit minutes and seconds' do
        track.duration = 67
        expect(track.formatted_duration).to eq('1:07')
      end
    end
  end
end
