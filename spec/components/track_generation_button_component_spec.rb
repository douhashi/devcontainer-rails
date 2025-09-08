require 'rails_helper'

RSpec.describe TrackGenerationButtonComponent, type: :component do
  let(:content) { create(:content, theme: "Test Theme", duration_min: 10, audio_prompt: "Test prompt") }

  describe 'rendering' do
    context 'when content is valid for generation' do
      it 'renders enabled button with generation and track count' do
        rendered = render_inline(described_class.new(content_record: content))

        expect(rendered).to have_css('button[data-controller="track-generation"]')
        expect(rendered).to have_css('button:not([disabled])')
        expect(rendered).to have_text('BGM生成開始（7回の生成で14曲）')
        expect(rendered).to have_css('[data-track-generation-music-generation-count-value="7"]')
        expect(rendered).to have_css('[data-track-generation-track-count-value="14"]')
        expect(rendered).to have_css('[data-track-generation-url-value]')
      end

      it 'includes confirmation data attributes' do
        rendered = render_inline(described_class.new(content_record: content))

        expect(rendered).to have_css('[data-track-generation-confirmation-message-value]')
        expect(rendered.to_html).to include('7回の音楽生成で14曲のトラックを作成します')
      end
    end

    context 'when content has no duration' do
      let(:invalid_content) { Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test') }

      it 'renders disabled button with error message' do
        rendered = render_inline(described_class.new(content_record: invalid_content))

        expect(rendered).to have_css('button[disabled]')
        expect(rendered).to have_text('BGM生成開始（0回の生成で0曲）')
        expect(rendered).to have_text('動画の長さが設定されていません')
        expect(rendered).not_to have_css('[data-controller="track-generation"]')
      end
    end

    context 'when content has no audio_prompt' do
      let(:invalid_content) { Content.new(theme: 'test', duration_min: 10, audio_prompt: nil) }

      it 'renders disabled button with error message' do
        rendered = render_inline(described_class.new(content_record: invalid_content))

        expect(rendered).to have_css('button[disabled]')
        expect(rendered).to have_text('BGM生成開始（7回の生成で14曲）')
        expect(rendered).to have_text('音楽生成プロンプトが設定されていません')
        expect(rendered).not_to have_css('[data-controller="track-generation"]')
      end
    end

    context 'when content has processing tracks' do
      before do
        create(:track, content: content, status: :processing)
      end

      it 'renders disabled button with processing message' do
        rendered = render_inline(described_class.new(content_record: content))

        expect(rendered).to have_css('button[disabled]')
        expect(rendered).to have_text('生成中...')
        expect(rendered).to have_text('BGM生成処理中です')
        expect(rendered).not_to have_css('[data-controller="track-generation"]')
      end
    end

    context 'when content would exceed track limit' do
      before do
        create_list(:track, 99, content: content)
      end

      it 'renders disabled button with limit message' do
        rendered = render_inline(described_class.new(content_record: content))

        expect(rendered).to have_css('button[disabled]')
        expect(rendered).to have_text('BGM生成開始（7回の生成で14曲）')
        expect(rendered).to have_text('トラック数の上限に達しています')
        expect(rendered).not_to have_css('[data-controller="track-generation"]')
      end
    end
  end

  describe '#track_count' do
    it 'calculates track count correctly' do
      component = described_class.new(content_record: content)
      # 10 minutes = 7 music generation * 2 tracks = 14 tracks with new formula
      expect(component.track_count).to eq(14)
    end
  end

  describe '#can_generate?' do
    let(:component) { described_class.new(content_record: content) }

    it 'returns true for valid content' do
      expect(component.can_generate?).to be true
    end

    it 'returns false when duration is missing' do
      invalid_content = Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test')
      component = described_class.new(content_record: invalid_content)
      expect(component.can_generate?).to be false
    end

    it 'returns false when audio_prompt is missing' do
      invalid_content = Content.new(theme: 'test', duration_min: 10, audio_prompt: nil)
      component = described_class.new(content_record: invalid_content)
      expect(component.can_generate?).to be false
    end

    it 'returns false when processing tracks exist' do
      create(:track, content: content, status: :processing)
      expect(component.can_generate?).to be false
    end

    it 'returns false when track limit would be exceeded' do
      create_list(:track, 99, content: content)
      expect(component.can_generate?).to be false
    end
  end

  describe '#disability_reason' do
    let(:component) { described_class.new(content_record: content) }

    it 'returns nil for valid content' do
      expect(component.disability_reason).to be_nil
    end

    it 'returns duration error when duration is missing' do
      invalid_content = Content.new(theme: 'test', duration_min: nil, audio_prompt: 'test')
      component = described_class.new(content_record: invalid_content)
      expect(component.disability_reason).to eq('動画の長さが設定されていません')
    end

    it 'returns audio_prompt error when audio_prompt is missing' do
      invalid_content = Content.new(theme: 'test', duration_min: 10, audio_prompt: nil)
      component = described_class.new(content_record: invalid_content)
      expect(component.disability_reason).to eq('音楽生成プロンプトが設定されていません')
    end

    it 'returns processing error when processing tracks exist' do
      create(:track, content: content, status: :processing)
      expect(component.disability_reason).to eq('BGM生成処理中です')
    end

    it 'returns limit error when track limit would be exceeded' do
      create_list(:track, 99, content: content)
      expect(component.disability_reason).to eq('トラック数の上限に達しています')
    end
  end

  describe '#button_text' do
    let(:component) { described_class.new(content_record: content) }

    it 'returns text with generation count and track count' do
      # 10 minutes duration = 7 music generation, 14 tracks with new formula
      expect(component.button_text).to eq('BGM生成開始（7回の生成で14曲）')
    end

    it 'returns processing text when processing tracks exist' do
      create(:track, content: content, status: :processing)
      expect(component.button_text).to eq('生成中...')
    end

    context 'with longer duration' do
      let(:content) { create(:content, duration_min: 1200) } # 1200 minutes = 205 generations, 410 tracks with new formula

      it 'shows correct generation and track counts' do
        expect(component.button_text).to eq('BGM生成開始（205回の生成で410曲）')
      end
    end
  end

  describe '#music_generation_count' do
    it 'calculates music generation count correctly' do
      component = described_class.new(content_record: content)
      # 10 minutes = 7 music generation with new formula
      expect(component.music_generation_count).to eq(7)
    end

    context 'with longer duration' do
      let(:content) { create(:content, duration_min: 1200) } # 1200 minutes

      it 'calculates correct generation count' do
        component = described_class.new(content_record: content)
        # 1200 minutes = (1200 / 6) + 5 = 200 + 5 = 205 generations with new formula
        expect(component.music_generation_count).to eq(205)
      end
    end
  end
end
