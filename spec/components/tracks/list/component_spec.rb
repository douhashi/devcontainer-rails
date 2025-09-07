require 'rails_helper'

RSpec.describe Tracks::List::Component, type: :component do
  let(:content) { create(:content) }

  describe 'rendering' do
    context 'with no tracks' do
      it 'shows empty state' do
        render_inline(described_class.new(tracks: Track.none))

        expect(page).to have_text('まだトラックが生成されていません')
        expect(page).to have_text('「BGM生成開始」ボタンを押して楽曲を生成してください')
      end
    end

    context 'with tracks' do
      let!(:pending_track) { create(:track, content: content, status: :pending) }
      let!(:processing_track) { create(:track, content: content, status: :processing) }
      let!(:completed_track) do
        track = create(:track, :completed, content: content, duration: 185)
        # Mock audio attachment for completed track
        audio_double = double(present?: true, url: '/test-audio.mp3')
        allow(track).to receive(:audio).and_return(audio_double)
        track
      end
      let!(:failed_track) { create(:track, :failed, content: content) }

      before do
        render_inline(described_class.new(tracks: content.tracks))
      end

      it 'displays track count' do
        expect(page).to have_text('トラック一覧 (4件)')
      end

      it 'shows pending track status' do
        expect(page).to have_text('待機中')
        expect(page).to have_text('⏳ 待機中')
      end

      it 'shows processing track status' do
        expect(page).to have_text('生成中')
        expect(page).to have_text('⚙️ 処理中...')
      end

      it 'shows completed track with duration' do
        expect(page).to have_text('完了')
        expect(page).to have_text('🎵 3:05') # formatted duration
      end

      it 'has logic to check audio availability' do
        component = described_class.new(tracks: content.tracks)
        completed_track_with_audio = double('track', status: double(completed?: true), audio: double(present?: true))
        completed_track_without_audio = double('track', status: double(completed?: true), audio: double(present?: false))
        pending_track = double('track', status: double(completed?: false), audio: double(present?: true))

        expect(component.send(:has_audio?, completed_track_with_audio)).to be true
        expect(component.send(:has_audio?, completed_track_without_audio)).to be false
        expect(component.send(:has_audio?, pending_track)).to be false
      end

      it 'shows failed track status' do
        expect(page).to have_text('失敗')
        expect(page).to have_text('❌ エラー:')
      end

      it 'shows track numbers' do
        expect(page).to have_text('#1')
        expect(page).to have_text('#2')
        expect(page).to have_text('#3')
        expect(page).to have_text('#4')
      end

      it 'shows creation dates' do
        expect(page).to have_text('作成:')
      end
    end

    context 'with different duration formats' do
      let!(:short_track) do
        track = create(:track, :completed, :with_short_duration, content: content)
        allow(track).to receive(:audio).and_return(double(present?: true, url: '/test-audio.mp3'))
        track
      end
      let!(:long_track) do
        track = create(:track, :completed, :with_long_duration, content: content)
        allow(track).to receive(:audio).and_return(double(present?: true, url: '/test-audio.mp3'))
        track
      end
      let!(:very_long_track) do
        track = create(:track, :completed, :with_very_long_duration, content: content)
        allow(track).to receive(:audio).and_return(double(present?: true, url: '/test-audio.mp3'))
        track
      end

      before do
        render_inline(described_class.new(tracks: content.tracks))
      end

      it 'formats short duration correctly' do
        expect(page).to have_text('🎵 1:30') # 90 seconds
      end

      it 'formats regular duration correctly' do
        expect(page).to have_text('🎵 5:00') # 300 seconds
      end

      it 'formats long duration with hours correctly' do
        expect(page).to have_text('🎵 1:01:05') # 3665 seconds
      end
    end
  end
end
