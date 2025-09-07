require 'rails_helper'

RSpec.describe Content, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:tracks).dependent(:destroy) }
  end

  describe 'validations' do
    it 'validates presence of theme' do
      content = Content.new(theme: nil)
      expect(content).not_to be_valid
      expect(content.errors[:theme]).to include("can't be blank")
    end

    it 'validates length of theme is at most 256 characters' do
      content = Content.new(theme: 'a' * 257)
      expect(content).not_to be_valid
      expect(content.errors[:theme]).to include('is too long (maximum is 256 characters)')
    end

    it 'validates presence of duration' do
      content = Content.new(duration: nil)
      expect(content).not_to be_valid
      expect(content.errors[:duration]).to include("can't be blank")
    end

    it 'validates duration is greater than 0' do
      content = Content.new(duration: 0)
      expect(content).not_to be_valid
      expect(content.errors[:duration]).to include('must be greater than 0')
    end

    it 'validates duration is less than or equal to 60' do
      content = Content.new(duration: 61)
      expect(content).not_to be_valid
      expect(content.errors[:duration]).to include('must be less than or equal to 60')
    end

    it 'validates presence of audio_prompt' do
      content = Content.new(audio_prompt: nil)
      expect(content).not_to be_valid
      expect(content.errors[:audio_prompt]).to include("can't be blank")
    end

    it 'validates length of audio_prompt is at most 1000 characters' do
      content = Content.new(audio_prompt: 'a' * 1001)
      expect(content).not_to be_valid
      expect(content.errors[:audio_prompt]).to include('is too long (maximum is 1000 characters)')
    end
  end

  describe 'theme attribute' do
    let(:content) { build(:content) }

    context 'with valid theme' do
      it 'is valid with a theme' do
        content.theme = 'レコード、古いスピーカー、ランプの明かり'
        expect(content).to be_valid
      end

      it 'is valid with 256 characters' do
        content.theme = 'a' * 256
        expect(content).to be_valid
      end
    end

    context 'with invalid theme' do
      it 'is invalid without a theme' do
        content.theme = nil
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include("can't be blank")
      end

      it 'is invalid with empty theme' do
        content.theme = ''
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include("can't be blank")
      end

      it 'is invalid with more than 256 characters' do
        content.theme = 'a' * 257
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include('is too long (maximum is 256 characters)')
      end
    end
  end

  describe 'duration attribute' do
    let(:content) { build(:content) }

    context 'with valid duration' do
      it 'is valid with duration of 1' do
        content.duration = 1
        expect(content).to be_valid
      end

      it 'is valid with duration of 30' do
        content.duration = 30
        expect(content).to be_valid
      end

      it 'is valid with duration of 60' do
        content.duration = 60
        expect(content).to be_valid
      end
    end

    context 'with invalid duration' do
      it 'is invalid with duration of 0' do
        content.duration = 0
        expect(content).not_to be_valid
        expect(content.errors[:duration]).to include('must be greater than 0')
      end

      it 'is invalid with negative duration' do
        content.duration = -1
        expect(content).not_to be_valid
        expect(content.errors[:duration]).to include('must be greater than 0')
      end

      it 'is invalid with duration greater than 60' do
        content.duration = 61
        expect(content).not_to be_valid
        expect(content.errors[:duration]).to include('must be less than or equal to 60')
      end

      it 'is invalid without duration' do
        content.duration = nil
        expect(content).not_to be_valid
        expect(content.errors[:duration]).to include("can't be blank")
      end
    end
  end

  describe 'audio_prompt attribute' do
    let(:content) { build(:content) }

    context 'with valid audio_prompt' do
      it 'is valid with short audio_prompt' do
        content.audio_prompt = 'Chill and relaxing music'
        expect(content).to be_valid
      end

      it 'is valid with long audio_prompt' do
        content.audio_prompt = 'a' * 1000
        expect(content).to be_valid
      end

      it 'is valid with Japanese audio_prompt' do
        content.audio_prompt = 'リラックスできる穏やかな音楽、自然の音、鳥のさえずり'
        expect(content).to be_valid
      end
    end

    context 'with invalid audio_prompt' do
      it 'is invalid without audio_prompt' do
        content.audio_prompt = nil
        expect(content).not_to be_valid
        expect(content.errors[:audio_prompt]).to include("can't be blank")
      end

      it 'is invalid with empty audio_prompt' do
        content.audio_prompt = ''
        expect(content).not_to be_valid
        expect(content.errors[:audio_prompt]).to include("can't be blank")
      end

      it 'is invalid with audio_prompt longer than 1000 characters' do
        content.audio_prompt = 'a' * 1001
        expect(content).not_to be_valid
        expect(content.errors[:audio_prompt]).to include('is too long (maximum is 1000 characters)')
      end
    end
  end

  describe 'dependent destroy' do
    let!(:content) { create(:content) }
    let!(:track1) { create(:track, content: content) }
    let!(:track2) { create(:track, content: content) }

    it 'destroys associated tracks when content is destroyed' do
      expect { content.destroy }.to change(Track, :count).by(-2)
    end
  end
end
