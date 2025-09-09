require 'rails_helper'

RSpec.describe Track, type: :model do
  describe 'validations' do
    describe 'variant_index' do
      let(:track) { build(:track) }

      it 'allows nil values' do
        track.variant_index = nil
        expect(track).to be_valid
      end

      it 'allows 0 or 1' do
        track.variant_index = 0
        expect(track).to be_valid

        track.variant_index = 1
        expect(track).to be_valid
      end

      it 'does not allow values other than 0 or 1' do
        track.variant_index = 2
        expect(track).to be_invalid
        expect(track.errors[:variant_index]).to include('is not included in the list')

        track.variant_index = -1
        expect(track).to be_invalid
        expect(track.errors[:variant_index]).to include('is not included in the list')
      end
    end

    describe 'duration' do
      let(:track) { build(:track, content: create(:content)) }

      it 'validates numericality of duration' do
        track.duration_sec = 'invalid'
        expect(track).to be_invalid
        expect(track.errors[:duration_sec]).to include('is not a number')
      end

      it 'allows positive integers' do
        track.duration_sec = 180
        expect(track).to be_valid
      end

      it 'allows nil values' do
        track.duration_sec = nil
        expect(track).to be_valid
      end

      it 'does not allow zero or negative values' do
        track.duration_sec = 0
        expect(track).to be_invalid
        expect(track.errors[:duration_sec]).to include('must be greater than 0')

        track.duration_sec = -10
        expect(track).to be_invalid
        expect(track.errors[:duration_sec]).to include('must be greater than 0')
      end
    end
  end

  describe '#formatted_duration' do
    let(:track) { build(:track) }

    context 'when duration is nil' do
      it 'returns "未取得"' do
        track.duration_sec = nil
        expect(track.formatted_duration).to eq('未取得')
      end
    end

    context 'when duration is present' do
      it 'formats duration as "M:SS" for durations under an hour' do
        track.duration_sec = 185
        expect(track.formatted_duration).to eq('3:05')
      end

      it 'formats duration as "H:MM:SS" for durations over an hour' do
        track.duration_sec = 3665
        expect(track.formatted_duration).to eq('1:01:05')
      end

      it 'handles zero correctly' do
        track.duration_sec = 0
        expect(track.formatted_duration).to eq('0:00')
      end

      it 'handles single digit minutes and seconds' do
        track.duration_sec = 67
        expect(track.formatted_duration).to eq('1:07')
      end
    end
  end

  describe 'metadata accessors' do
    let(:track) { build(:track) }

    describe '#metadata_title' do
      it 'returns the title from metadata' do
        track.metadata = { 'music_title' => 'Lo-fi Beat' }
        expect(track.metadata_title).to eq('Lo-fi Beat')
      end

      it 'returns nil when metadata is empty' do
        track.metadata = {}
        expect(track.metadata_title).to be_nil
      end

      it 'returns nil when metadata is nil' do
        track.metadata = nil
        expect(track.metadata_title).to be_nil
      end
    end

    describe '#metadata_tags' do
      it 'returns the tags from metadata' do
        track.metadata = { 'music_tags' => 'lo-fi,chill,study' }
        expect(track.metadata_tags).to eq('lo-fi,chill,study')
      end

      it 'returns nil when metadata is empty' do
        track.metadata = {}
        expect(track.metadata_tags).to be_nil
      end
    end

    describe '#metadata_model_name' do
      it 'returns the model name from metadata' do
        track.metadata = { 'model_name' => 'chirp-v3-5' }
        expect(track.metadata_model_name).to eq('chirp-v3-5')
      end

      it 'returns nil when metadata is empty' do
        track.metadata = {}
        expect(track.metadata_model_name).to be_nil
      end
    end

    describe '#metadata_generated_prompt' do
      it 'returns the generated prompt from metadata' do
        track.metadata = { 'generated_prompt' => '[Verse]\nSoft beats...' }
        expect(track.metadata_generated_prompt).to eq('[Verse]\nSoft beats...')
      end

      it 'returns nil when metadata is empty' do
        track.metadata = {}
        expect(track.metadata_generated_prompt).to be_nil
      end
    end

    describe '#metadata_audio_id' do
      it 'returns the audio ID from metadata' do
        track.metadata = { 'audio_id' => '4ed5f074-07d7-42e6-83d6-0b1db3dd0064' }
        expect(track.metadata_audio_id).to eq('4ed5f074-07d7-42e6-83d6-0b1db3dd0064')
      end

      it 'returns nil when metadata is empty' do
        track.metadata = {}
        expect(track.metadata_audio_id).to be_nil
      end
    end

    describe '#has_metadata?' do
      it 'returns true when metadata contains music information' do
        track.metadata = { 'music_title' => 'Test', 'music_tags' => 'tags' }
        expect(track.has_metadata?).to be true
      end

      it 'returns false when metadata is empty' do
        track.metadata = {}
        expect(track.has_metadata?).to be false
      end

      it 'returns false when metadata is nil' do
        track.metadata = nil
        expect(track.has_metadata?).to be false
      end

      it 'returns false when metadata only has non-music fields' do
        track.metadata = { 'task_id' => '123', 'polling_attempts' => 1 }
        expect(track.has_metadata?).to be false
      end
    end
  end
end
