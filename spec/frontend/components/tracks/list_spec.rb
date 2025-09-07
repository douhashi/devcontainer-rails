# frozen_string_literal: true

require "rails_helper"

describe Tracks::List::Component, type: :view_component do
  let(:tracks) { [] }
  let(:component) { Tracks::List::Component.new(tracks: tracks) }

  subject { rendered_content }

  describe 'rendering' do
    context 'when no tracks exist' do
      it 'shows empty state message' do
        render_inline(component)

        is_expected.to have_text('まだトラックが生成されていません')
        is_expected.to have_text('「BGM生成開始」ボタンを押して楽曲を生成してください')
      end
    end

    context 'when tracks exist with metadata' do
      let(:track_with_metadata) do
        create(:track,
          status: :completed,
          duration: 240,
          metadata: {
            'music_title' => 'Chill Lo-fi Beat',
            'music_tags' => 'lo-fi, relaxing, study'
          }
        )
      end

      let(:track_without_metadata) do
        create(:track,
          status: :completed,
          duration: 180,
          metadata: {}
        )
      end

      let(:tracks) { [ track_with_metadata, track_without_metadata ] }

      before do
        # Mock ApplicationController.render for TrackStatus component
        allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")
      end

      it 'displays track count' do
        render_inline(component)

        is_expected.to have_text('トラック一覧 (2件)')
      end

      it 'displays metadata title when present' do
        render_inline(component)

        is_expected.to have_text('Chill Lo-fi Beat')
      end

      it 'displays metadata tags when present' do
        render_inline(component)

        is_expected.to have_text('タグ: lo-fi, relaxing, study')
      end

      it 'displays duration for all tracks' do
        render_inline(component)

        is_expected.to have_text('4:00')  # track_with_metadata
        is_expected.to have_text('3:00')  # track_without_metadata
      end

      it 'does not display metadata for tracks without it' do
        render_inline(component)

        # Check that the page has metadata for track_with_metadata
        is_expected.to have_text('タグ: lo-fi, relaxing, study')

        # But the total count of 'タグ:' should be only 1 (from track_with_metadata)
        tag_count = subject.to_s.scan(/タグ:/).count
        expect(tag_count).to eq(1)
      end
    end

    context 'when tracks have different statuses' do
      let(:pending_track) { create(:track, status: :pending) }
      let(:processing_track) { create(:track, status: :processing) }
      let(:completed_track) { create(:track, status: :completed) }
      let(:failed_track) do
        create(:track,
          status: :failed,
          metadata: { 'error' => 'Generation failed due to insufficient credits' }
        )
      end

      let(:tracks) { [ pending_track, processing_track, completed_track, failed_track ] }

      before do
        allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")
      end

      it 'displays appropriate status messages' do
        render_inline(component)

        is_expected.to have_text('⏳ 待機中')
        is_expected.to have_text('⚙️ 処理中...')
        is_expected.to have_text('❌ エラー')
      end

      it 'displays error message for failed tracks' do
        render_inline(component)

        is_expected.to have_text('Generation failed due to insufficient')
      end
    end
  end

  describe '#ordered_tracks' do
    let(:old_track) { create(:track, created_at: 2.days.ago) }
    let(:new_track) { create(:track, created_at: 1.day.ago) }
    let(:tracks) { [ new_track, old_track ] }

    it 'orders tracks by created_at' do
      ordered = component.send(:ordered_tracks)
      expect(ordered.first).to eq(old_track)
      expect(ordered.last).to eq(new_track)
    end
  end

  describe '#formatted_created_at' do
    let(:track) { create(:track, created_at: Time.zone.parse('2025-09-07 15:30:00')) }
    let(:tracks) { [ track ] }

    it 'formats creation date correctly' do
      expect(component.send(:formatted_created_at, track)).to eq('2025/09/07 15:30')
    end
  end
end
