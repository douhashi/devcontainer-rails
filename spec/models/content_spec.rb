require 'rails_helper'

RSpec.describe Content, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:tracks).dependent(:destroy) }
    it { is_expected.to have_one(:artwork).dependent(:destroy) }
    it { is_expected.to have_one(:audio).dependent(:destroy) }
    it { is_expected.to have_one(:video).dependent(:destroy) }
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
      content = Content.new(duration_min: nil)
      expect(content).not_to be_valid
      expect(content.errors[:duration_min]).to include("can't be blank")
    end

    it 'validates duration is greater than 0' do
      content = Content.new(duration_min: 0)
      expect(content).not_to be_valid
      expect(content.errors[:duration_min]).to include('must be greater than 0')
    end

    # 60分上限制限が撤廃されたため、61分以上も有効になる
    it 'allows duration greater than 60' do
      content = Content.new(duration_min: 61, theme: 'test', audio_prompt: 'test')
      content.valid?
      expect(content.errors[:duration_min]).to be_empty
    end

    it 'allows duration of 120 minutes' do
      content = Content.new(duration_min: 120, theme: 'test', audio_prompt: 'test')
      content.valid?
      expect(content.errors[:duration_min]).to be_empty
    end

    it 'allows duration of 180 minutes' do
      content = Content.new(duration_min: 180, theme: 'test', audio_prompt: 'test')
      content.valid?
      expect(content.errors[:duration_min]).to be_empty
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
        content.duration_min = 1
        expect(content).to be_valid
      end

      it 'is valid with duration of 30' do
        content.duration_min = 30
        expect(content).to be_valid
      end

      it 'is valid with duration of 60' do
        content.duration_min = 60
        expect(content).to be_valid
      end
    end

    context 'with invalid duration' do
      it 'is invalid with duration of 0' do
        content.duration_min = 0
        expect(content).not_to be_valid
        expect(content.errors[:duration_min]).to include('must be greater than 0')
      end

      it 'is invalid with negative duration' do
        content.duration_min = -1
        expect(content).not_to be_valid
        expect(content.errors[:duration_min]).to include('must be greater than 0')
      end

      it 'is valid with duration greater than 60' do
        content.duration_min = 61
        expect(content).to be_valid
      end

      it 'is valid with duration of 120' do
        content.duration_min = 120
        expect(content).to be_valid
      end

      it 'is valid with duration of 180' do
        content.duration_min = 180
        expect(content).to be_valid
      end

      it 'is valid with very long duration' do
        content.duration_min = 600
        expect(content).to be_valid
      end

      it 'is invalid without duration' do
        content.duration_min = nil
        expect(content).not_to be_valid
        expect(content.errors[:duration_min]).to include("can't be blank")
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
    let!(:artwork) { create(:artwork, content: content) }

    it 'destroys associated tracks when content is destroyed' do
      expect { content.destroy }.to change(Track, :count).by(-2)
    end

    it 'destroys associated artwork when content is destroyed' do
      expect { content.destroy }.to change(Artwork, :count).by(-1)
    end
  end

  describe 'status-related methods' do
    let(:content) { create(:content, duration_min: 12) }

    describe '#required_track_count' do
      it 'delegates to MusicGenerationQueueingService for calculation' do
        # MusicGenerationQueueingService returns music generation count using new formula
        # Each music generation produces 2 tracks
        # 12 minutes: (12 / 6) + 5 = 2 + 5 = 7 generations * 2 tracks = 14 tracks
        expect(content.required_track_count).to eq(14)
      end

      context 'with various durations' do
        it 'calculates correct count for 6 minutes' do
          content.duration_min = 6
          # 6 minutes: (6 / 6) + 5 = 1 + 5 = 6 generations * 2 tracks = 12 tracks
          expect(content.required_track_count).to eq(12)
        end

        it 'calculates correct count for 30 minutes' do
          content.duration_min = 30
          # 30 minutes: (30 / 6) + 5 = 5 + 5 = 10 generations * 2 tracks = 20 tracks
          expect(content.required_track_count).to eq(20)
        end
      end
    end

    describe '#track_progress' do
      before do
        create_list(:track, 3, content: content, status: :completed)
        create_list(:track, 2, content: content, status: :pending)
      end

      it 'returns progress as hash with completed and total counts' do
        progress = content.track_progress
        expect(progress[:completed]).to eq(3)
        expect(progress[:total]).to eq(content.required_track_count)
        expect(progress[:percentage]).to eq((3.0 / content.required_track_count * 100).round(1))
      end

      context 'when no tracks exist' do
        let(:content_no_tracks) { create(:content, duration_min: 12) }

        it 'returns zero completed tracks' do
          progress = content_no_tracks.track_progress
          expect(progress[:completed]).to eq(0)
          expect(progress[:total]).to eq(content_no_tracks.required_track_count)
          expect(progress[:percentage]).to eq(0.0)
        end
      end
    end

    describe '#artwork_status' do
      context 'when artwork exists' do
        before { create(:artwork, content: content) }

        it 'returns configured status' do
          expect(content.artwork_status).to eq(:configured)
        end
      end

      context 'when artwork does not exist' do
        it 'returns not_configured status' do
          expect(content.artwork_status).to eq(:not_configured)
        end
      end
    end

    describe '#completion_status' do
      context 'when all tracks are completed and artwork is configured' do
        before do
          required_count = content.required_track_count
          create_list(:track, required_count, content: content, status: :completed)
          create(:artwork, content: content)
        end

        it 'returns completed status' do
          expect(content.completion_status).to eq(:completed)
        end
      end

      context 'when tracks are in progress' do
        before do
          create_list(:track, 2, content: content, status: :completed)
          create_list(:track, 2, content: content, status: :processing)
        end

        it 'returns in_progress status' do
          expect(content.completion_status).to eq(:in_progress)
        end
      end

      context 'when some tracks have failed' do
        before do
          create_list(:track, 2, content: content, status: :completed)
          create_list(:track, 1, content: content, status: :failed)
        end

        it 'returns needs_attention status' do
          expect(content.completion_status).to eq(:needs_attention)
        end
      end

      context 'when no tracks exist' do
        it 'returns not_started status' do
          expect(content.completion_status).to eq(:not_started)
        end
      end
    end
  end

  describe '#music_generation_progress' do
    let(:content) { create(:content, duration_min: 20) } # 20 minutes = 9 music generations with new formula

    context 'when music generations exist' do
      before do
        # Create 5 completed and 3 pending music generation
        create_list(:music_generation, 5, content: content, status: :completed)
        create_list(:music_generation, 3, content: content, status: :pending)
      end

      it 'returns correct progress information' do
        progress = content.music_generation_progress
        expect(progress[:completed]).to eq(5)
        expect(progress[:total]).to eq(9)
        expect(progress[:percentage]).to eq(55.6)
      end
    end

    context 'when no music generations exist' do
      it 'returns zero progress' do
        progress = content.music_generation_progress
        expect(progress[:completed]).to eq(0)
        expect(progress[:total]).to eq(9)
        expect(progress[:percentage]).to eq(0.0)
      end
    end

    context 'when all music generations are completed' do
      before do
        create_list(:music_generation, 9, content: content, status: :completed)
      end

      it 'returns 100% progress' do
        progress = content.music_generation_progress
        expect(progress[:completed]).to eq(9)
        expect(progress[:total]).to eq(9)
        expect(progress[:percentage]).to eq(100.0)
      end
    end

    context 'with various statuses' do
      before do
        create(:music_generation, content: content, status: :completed)
        create(:music_generation, content: content, status: :processing)
        create(:music_generation, content: content, status: :failed)
      end

      it 'only counts completed generations' do
        progress = content.music_generation_progress
        expect(progress[:completed]).to eq(1)
        expect(progress[:total]).to eq(9)
        expect(progress[:percentage]).to eq(11.1)
      end
    end
  end

  describe '#required_music_generation_count' do
    let(:content) { create(:content) }

    it 'calculates correct count for various durations using new formula' do
      content.duration_min = 6 # 6 minutes: (6 / 6) + 5 = 1 + 5 = 6 generations
      expect(content.required_music_generation_count).to eq(6)

      content.duration_min = 12 # 12 minutes: (12 / 6) + 5 = 2 + 5 = 7 generations
      expect(content.required_music_generation_count).to eq(7)

      content.duration_min = 20 # 20 minutes: (20 / 6) + 5 = 3.33 + 5 = 8.33 -> 9 generations
      expect(content.required_music_generation_count).to eq(9)

      content.duration_min = 60 # 60 minutes: (60 / 6) + 5 = 10 + 5 = 15 generations
      expect(content.required_music_generation_count).to eq(15)
    end
  end

  describe '#tracks_complete?' do
    let(:content) { create(:content, duration_min: 10) }

    context 'when total track duration exceeds content duration' do
      before do
        # 10分 = 600秒を超える duration を持つトラックを作成
        create(:track, content: content, status: :completed, duration_sec: 350)
        create(:track, content: content, status: :completed, duration_sec: 300)
      end

      it 'returns true' do
        expect(content.tracks_complete?).to be true
      end
    end

    context 'when total track duration equals content duration' do
      before do
        # ちょうど10分 = 600秒
        create(:track, content: content, status: :completed, duration_sec: 300)
        create(:track, content: content, status: :completed, duration_sec: 300)
      end

      it 'returns true' do
        expect(content.tracks_complete?).to be true
      end
    end

    context 'when total track duration is less than content duration' do
      before do
        # 10分 = 600秒に満たない
        create(:track, content: content, status: :completed, duration_sec: 200)
        create(:track, content: content, status: :completed, duration_sec: 300)
      end

      it 'returns false' do
        expect(content.tracks_complete?).to be false
      end
    end

    context 'when tracks have nil duration_sec' do
      before do
        create(:track, content: content, status: :completed, duration_sec: nil)
        create(:track, content: content, status: :completed, duration_sec: 300)
      end

      it 'treats nil as 0 and returns false' do
        expect(content.tracks_complete?).to be false
      end
    end

    context 'when no tracks exist' do
      it 'returns false' do
        expect(content.tracks_complete?).to be false
      end
    end

    context 'when only pending tracks exist' do
      before do
        create(:track, content: content, status: :pending, duration_sec: 400)
        create(:track, content: content, status: :pending, duration_sec: 300)
      end

      it 'returns false even if total duration would be sufficient' do
        expect(content.tracks_complete?).to be false
      end
    end
  end

  describe '#video_generated?' do
    let(:content) { create(:content) }

    context 'when video exists and is completed' do
      before do
        create(:video, content: content, status: :completed)
      end

      it 'returns true' do
        expect(content.video_generated?).to be true
      end
    end

    context 'when video exists but is not completed' do
      it 'returns false for pending video' do
        create(:video, content: content, status: :pending)
        expect(content.video_generated?).to be false
      end

      it 'returns false for processing video' do
        create(:video, content: content, status: :processing)
        expect(content.video_generated?).to be false
      end

      it 'returns false for failed video' do
        create(:video, content: content, status: :failed)
        expect(content.video_generated?).to be false
      end
    end

    context 'when no video exists' do
      it 'returns false' do
        expect(content.video_generated?).to be false
      end
    end
  end

  describe 'video generation methods' do
    let(:content) { create(:content) }

    describe '#video_generation_prerequisites_met?' do
      context 'when both audio and artwork are ready' do
        before do
          create(:audio, :completed, content: content)
          create(:artwork, content: content)
        end

        it 'returns true' do
          expect(content.video_generation_prerequisites_met?).to be true
        end
      end

      context 'when audio is missing' do
        before do
          create(:artwork, content: content)
        end

        it 'returns false' do
          expect(content.video_generation_prerequisites_met?).to be false
        end
      end

      context 'when audio is not completed' do
        before do
          create(:audio, :pending, content: content)
          create(:artwork, content: content)
        end

        it 'returns false' do
          expect(content.video_generation_prerequisites_met?).to be false
        end
      end

      context 'when artwork is missing' do
        before do
          create(:audio, :completed, content: content)
        end

        it 'returns false' do
          expect(content.video_generation_prerequisites_met?).to be false
        end
      end
    end

    describe '#video_generation_missing_prerequisites' do
      context 'when both prerequisites are missing' do
        it 'returns both missing messages' do
          missing = content.video_generation_missing_prerequisites
          expect(missing).to include('オーディオが完成していません')
          expect(missing).to include('アートワークが設定されていません')
        end
      end

      context 'when only audio is missing' do
        before do
          create(:artwork, content: content)
        end

        it 'returns only audio missing message' do
          missing = content.video_generation_missing_prerequisites
          expect(missing).to include('オーディオが完成していません')
          expect(missing).not_to include('アートワークが設定されていません')
        end
      end

      context 'when all prerequisites are met' do
        before do
          create(:audio, :completed, content: content)
          create(:artwork, content: content)
        end

        it 'returns empty array' do
          missing = content.video_generation_missing_prerequisites
          expect(missing).to be_empty
        end
      end
    end

    describe '#video_status' do
      context 'when prerequisites are not met' do
        it 'returns not_configured' do
          expect(content.video_status).to eq(:not_configured)
        end
      end

      context 'when prerequisites are met but video does not exist' do
        before do
          create(:audio, :completed, content: content)
          create(:artwork, content: content)
        end

        it 'returns not_created' do
          expect(content.video_status).to eq(:not_created)
        end
      end

      context 'when video exists' do
        before do
          create(:audio, :completed, content: content)
          create(:artwork, content: content)
        end

        it 'returns pending for pending video' do
          create(:video, :pending, content: content)
          expect(content.video_status).to eq(:pending)
        end

        it 'returns processing for processing video' do
          create(:video, :processing, content: content)
          expect(content.video_status).to eq(:processing)
        end

        it 'returns completed for completed video' do
          create(:video, :completed, content: content)
          expect(content.video_status).to eq(:completed)
        end

        it 'returns failed for failed video' do
          create(:video, :failed, content: content)
          expect(content.video_status).to eq(:failed)
        end
      end
    end
  end
end
