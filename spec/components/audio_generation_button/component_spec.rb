require 'rails_helper'

RSpec.describe AudioGenerationButton::Component, type: :component do
  let(:content) { create(:content) }
  let(:component) { described_class.new(content_record: content) }

  describe '#render?' do
    it 'renders the component' do
      expect(component.render?).to be true
    end
  end

  describe 'UI simplification' do
    context 'when audio does not exist' do
      it 'does not show status description text' do
        result = render_inline(component)
        expect(result.text).not_to include('音源ステータス')
        expect(result.text).not_to include('生成待機中です')
      end

      it 'shows generate button' do
        result = render_inline(component)
        expect(result.text).to include('音源を生成')
      end
    end

    context 'when audio exists with pending status' do
      let!(:audio) { create(:audio, content: content, status: :pending) }

      it 'shows status badge instead of description text' do
        result = render_inline(component)
        expect(result.css('[data-status="pending"]')).to be_present
      end

      it 'disables the generate button' do
        result = render_inline(component)
        expect(result.css('button[disabled]')).to be_present
      end
    end

    context 'when audio exists with processing status' do
      let!(:audio) { create(:audio, content: content, status: :processing) }

      it 'shows processing status badge with animation' do
        result = render_inline(component)
        expect(result.css('[data-status="processing"]')).to be_present
        expect(result.css('.animate-pulse')).to be_present
      end

      it 'disables the generate button' do
        result = render_inline(component)
        expect(result.css('button[disabled]')).to be_present
      end
    end

    context 'when audio exists with completed status' do
      let!(:audio) { create(:audio, content: content, status: :completed) }

      it 'shows completed status badge' do
        result = render_inline(component)
        expect(result.css('[data-status="completed"]')).to be_present
      end

      it 'shows play button for floating player' do
        allow(audio).to receive_message_chain(:audio, :url).and_return('/test/audio.mp3')
        allow(audio).to receive_message_chain(:audio, :present?).and_return(true)
        result = render_inline(component)
        expect(result.css('[data-controller*="floating-audio-player"]')).to be_present
      end

      it 'shows delete button' do
        result = render_inline(component)
        expect(result.text).to include('削除')
      end

      it 'does not show embedded audio player' do
        result = render_inline(component)
        expect(result.css('audio')).not_to be_present
      end
    end

    context 'when audio exists with failed status' do
      let!(:audio) { create(:audio, content: content, status: :failed) }

      it 'shows failed status badge' do
        result = render_inline(component)
        expect(result.css('[data-status="failed"]')).to be_present
      end

      it 'shows delete button' do
        result = render_inline(component)
        expect(result.text).to include('削除')
      end
    end
  end

  describe 'button state management' do
    context 'when prerequisites are not met' do
      it 'disables the generate button when no tracks' do
        result = render_inline(component)
        expect(result.css('button[disabled]')).to be_present
      end

      it 'disables the generate button when no artwork' do
        create(:track, content: content, status: :completed, duration_sec: 180)
        result = render_inline(component)
        expect(result.css('button[disabled]')).to be_present
      end
    end

    context 'when prerequisites are met' do
      before do
        # Create an artwork instead of attaching a file
        artwork = create(:artwork, :with_image)
        content.artwork = artwork
        content.save!
        create_list(:track, 2, content: content, status: :completed, duration_sec: 180)
      end

      context 'without audio' do
        it 'shows generate button enabled' do
          result = render_inline(component)
          expect(result.css('button:not([disabled])')).to be_present
          expect(result.text).to include('音源を生成')
        end
      end

      context 'with completed audio' do
        let!(:audio) { create(:audio, content: content, status: :completed) }

        it 'shows delete button instead of generate button in same space' do
          result = render_inline(component)
          buttons = result.css('button')
          expect(buttons.size).to eq(1)
          expect(result.text).to include('削除')
        end
      end
    end
  end

  describe 'floating player integration' do
    let!(:audio) { create(:audio, content: content, status: :completed) }

    before do
      allow(audio).to receive_message_chain(:audio, :url).and_return('/test/audio.mp3')
    end

    it 'includes play button with floating player controller' do
      result = render_inline(component)
      expect(result.css('[data-controller*="floating-audio-player"]')).to be_present
    end

    it 'includes audio data for floating player' do
      result = render_inline(component)
      play_button = result.css('[data-controller*="floating-audio-player"]').first
      expect(play_button).to be_present
    end
  end
end
