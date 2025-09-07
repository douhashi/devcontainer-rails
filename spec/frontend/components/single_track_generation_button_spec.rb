require 'rails_helper'

RSpec.describe SingleTrackGenerationButton::Component, type: :component do
  let(:content) { create(:content, duration: 10, audio_prompt: 'Test prompt') }
  subject(:component) { described_class.new(content_record: content) }

  describe '#initialize' do
    it 'initializes with content_record' do
      expect(component.content_record).to eq(content)
    end
  end

  describe '#can_generate?' do
    context 'when all conditions are met' do
      it 'returns true' do
        expect(component.can_generate?).to be true
      end
    end

    context 'when duration is missing' do
      let(:content) { build(:content, duration: nil, audio_prompt: 'Test prompt') }

      it 'returns false' do
        expect(component.can_generate?).to be false
      end
    end

    context 'when audio_prompt is missing' do
      let(:content) { build(:content, duration: 10, audio_prompt: nil) }

      it 'returns false' do
        expect(component.can_generate?).to be false
      end
    end

    context 'when tracks are being processed' do
      before do
        create(:track, content: content, status: :processing)
      end

      it 'returns false' do
        expect(component.can_generate?).to be false
      end
    end

    context 'when track limit would be exceeded' do
      before do
        create_list(:track, 100, content: content)
      end

      it 'returns false' do
        expect(component.can_generate?).to be false
      end
    end

    context 'when content has 99 tracks' do
      before do
        create_list(:track, 99, content: content)
      end

      it 'returns true (can add one more)' do
        expect(component.can_generate?).to be true
      end
    end
  end

  describe '#disability_reason' do
    context 'when all conditions are met' do
      it 'returns nil' do
        expect(component.disability_reason).to be_nil
      end
    end

    context 'when duration is missing' do
      let(:content) { build(:content, duration: nil, audio_prompt: 'Test prompt') }

      it 'returns appropriate message' do
        expect(component.disability_reason).to eq("動画の長さが設定されていません")
      end
    end

    context 'when audio_prompt is missing' do
      let(:content) { build(:content, duration: 10, audio_prompt: nil) }

      it 'returns appropriate message' do
        expect(component.disability_reason).to eq("音楽生成プロンプトが設定されていません")
      end
    end

    context 'when tracks are being processed' do
      before do
        create(:track, content: content, status: :processing)
      end

      it 'returns appropriate message' do
        expect(component.disability_reason).to eq("BGM生成処理中です")
      end
    end

    context 'when track limit would be exceeded' do
      before do
        create_list(:track, 100, content: content)
      end

      it 'returns appropriate message' do
        expect(component.disability_reason).to eq("トラック数の上限に達しています")
      end
    end
  end

  describe '#button_text' do
    context 'when not processing' do
      it 'returns default text' do
        expect(component.button_text).to eq("1件生成")
      end
    end

    context 'when processing tracks' do
      before do
        create(:track, content: content, status: :processing)
      end

      it 'returns processing text' do
        expect(component.button_text).to eq("生成中...")
      end
    end
  end

  describe '#confirmation_message' do
    it 'returns confirmation message for single track' do
      expect(component.confirmation_message).to eq("1件のトラックを生成します。よろしいですか？")
    end
  end

  describe '#generate_single_track_url' do
    it 'returns the correct URL' do
      expect(component.generate_single_track_url).to eq(
        Rails.application.routes.url_helpers.generate_single_track_content_path(content)
      )
    end
  end

  describe 'rendering' do
    it 'renders the component' do
      render_inline(component)

      expect(page).to have_button("1件生成")
    end

    context 'when can generate' do
      it 'renders enabled button with data attributes' do
        render_inline(component)

        button = page.find('button[data-controller="single-track-generation"]')
        expect(button).not_to be_disabled
        expect(button['data-single-track-generation-url-value']).to include('generate_single_track')
        expect(button['data-single-track-generation-confirmation-message-value']).to include('1件のトラック')
      end
    end

    context 'when cannot generate' do
      before do
        create(:track, content: content, status: :processing)
      end

      it 'renders disabled button with reason' do
        render_inline(component)

        expect(page).to have_button("生成中...", disabled: true)
        expect(page).to have_text("BGM生成処理中です")
      end
    end
  end
end
