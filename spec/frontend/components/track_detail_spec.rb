# frozen_string_literal: true

require "rails_helper"

describe TrackDetail::Component, type: :view_component do
  let(:track) { create(:track, metadata: metadata) }
  let(:component) { TrackDetail::Component.new(track: track) }
  let(:metadata) do
    {
      'music_title' => 'Lo-fi Study Beat',
      'music_tags' => 'lo-fi, chill, study',
      'model_name' => 'chirp-v3-5',
      'generated_prompt' => '[Verse]\nSoft beats in the night...',
      'audio_id' => '4ed5f074-07d7-42e6-83d6-0b1db3dd0064'
    }
  end

  subject { rendered_content }

  describe '#render?' do
    context 'when track has metadata' do
      it 'returns true' do
        expect(component.render?).to be true
      end
    end

    context 'when track has no metadata' do
      let(:metadata) { {} }

      it 'returns false' do
        expect(component.render?).to be false
      end
    end

    context 'when track is nil' do
      let(:track) { nil }

      it 'returns false' do
        expect(component.render?).to be false
      end
    end
  end

  describe 'rendering' do
    context 'with full metadata' do
      before do
        track.update!(duration_sec: 240)
      end

      it 'renders all metadata fields' do
        render_inline(component)

        is_expected.to have_css('.track-detail')
        is_expected.to have_text('Track メタデータ')
        is_expected.to have_text('タイトル:')
        is_expected.to have_text('Lo-fi Study Beat')
        is_expected.to have_text('タグ:')
        is_expected.to have_text('lo-fi, chill, study')
        is_expected.to have_text('再生時間:')
        is_expected.to have_text('4:00')
        is_expected.to have_text('生成モデル:')
        is_expected.to have_text('chirp-v3-5')
        is_expected.to have_text('Audio ID:')
        is_expected.to have_text('4ed5f074-07d7-42e6-83d6-0b1db3dd0064')
        is_expected.to have_text('生成プロンプト:')
        is_expected.to have_text('[Verse]\nSoft beats in the night...')
      end
    end

    context 'with partial metadata' do
      let(:metadata) do
        {
          'music_title' => 'Lo-fi Beat',
          'music_tags' => 'lo-fi'
        }
      end

      it 'renders only available fields' do
        render_inline(component)

        is_expected.to have_text('タイトル:')
        is_expected.to have_text('Lo-fi Beat')
        is_expected.to have_text('タグ:')
        is_expected.to have_text('lo-fi')
        is_expected.not_to have_text('生成モデル:')
        is_expected.not_to have_text('Audio ID:')
        is_expected.not_to have_text('生成プロンプト:')
      end
    end

    context 'with long prompt' do
      let(:metadata) do
        {
          'music_title' => 'Test',
          'generated_prompt' => 'A' * 300
        }
      end

      it 'truncates the prompt to 200 characters' do
        render_inline(component)

        is_expected.to have_css('.bg-gray-50')
        # The truncated prompt should be around 200 characters plus ellipsis
        is_expected.to have_text('A' * 197 + '...')
      end
    end
  end

  describe '#formatted_tags' do
    context 'when tags are comma-separated with spaces' do
      let(:metadata) { { 'music_tags' => 'lo-fi,  chill  ,study' } }

      it 'formats tags with consistent spacing' do
        expect(component.formatted_tags).to eq('lo-fi, chill, study')
      end
    end

    context 'when tags are nil' do
      let(:metadata) { {} }

      it 'returns nil' do
        expect(component.formatted_tags).to be_nil
      end
    end
  end

  describe '#truncated_prompt' do
    context 'when prompt is longer than 200 characters' do
      let(:metadata) { { 'generated_prompt' => 'A' * 300 } }

      it 'truncates to 200 characters' do
        expect(component.truncated_prompt.length).to be <= 203
        expect(component.truncated_prompt).to end_with('...')
      end
    end

    context 'when prompt is shorter than 200 characters' do
      let(:metadata) { { 'generated_prompt' => 'Short prompt' } }

      it 'returns the full prompt' do
        expect(component.truncated_prompt).to eq('Short prompt')
      end
    end

    context 'when prompt is nil' do
      let(:metadata) { {} }

      it 'returns nil' do
        expect(component.truncated_prompt).to be_nil
      end
    end
  end
end
