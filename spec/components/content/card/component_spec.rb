require 'rails_helper'

RSpec.describe Content::Card::Component, type: :component do
  let(:content) { create(:content, theme: 'LoFi Study Music', duration_min: 12, audio_prompt: 'Chill beats for studying') }
  let(:component) { described_class.new(item: content) }

  before do
    # Setup tracks and artwork for different completion status scenarios
    allow(content).to receive(:track_progress).and_return({ completed: 3, total: 7, percentage: 42.9 })
    allow(content).to receive(:artwork_status).and_return(:not_configured)
    allow(content).to receive(:completion_status).and_return(:in_progress)
  end

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders content card with basic information' do
      expect(subject.text).to include('LoFi Study Music')
      expect(subject.text).to include('12分')
      # audio_prompt は新デザインでは表示されない
    end

    it 'includes data attributes for filtering' do
      expect(subject.css('[data-content-id]')).to be_present
      expect(subject.css('[data-completion-status="in_progress"]')).to be_present
    end

    it 'displays progress icons' do
      # 新デザインではアイコンで進捗を表示
      expect(subject.css('svg')).to be_present
      # 3つのアイコン（image, music, video）が存在することを確認
      expect(subject.css('svg').count).to be >= 3
    end

    it 'displays completion status badge' do
      expect(subject.css('[data-status="in_progress"]')).to be_present
      expect(subject.text).to include('制作中')
    end

    it 'includes hover effects and transitions' do
      expect(subject.css('.hover\\:bg-gray-700')).to be_present
      expect(subject.css('.transition-colors')).to be_present
    end

    context 'with completed content' do
      before do
        allow(content).to receive(:track_progress).and_return({ completed: 7, total: 7, percentage: 100.0 })
        allow(content).to receive(:artwork_status).and_return(:configured)
        allow(content).to receive(:completion_status).and_return(:completed)
      end

      it 'shows completed status' do
        result = render_inline(component)
        expect(result.css('[data-completion-status="completed"]')).to be_present
        expect(result.css('[data-status="completed"]')).to be_present
      end

      it 'shows completed icons' do
        result = render_inline(component)
        # 完了したコンテンツは緑色のアイコンを持つ
        expect(result.css('.text-green-500')).to be_present
      end

      it 'shows artwork configured status' do
        result = render_inline(component)
        expect(result.css('.text-green-500')).to be_present # Configured artwork icon
      end
    end

    context 'with content needing attention' do
      before do
        allow(content).to receive(:completion_status).and_return(:needs_attention)
      end

      it 'shows needs attention status' do
        result = render_inline(component)
        expect(result.css('[data-completion-status="needs_attention"]')).to be_present
        expect(result.css('[data-status="needs_attention"]')).to be_present
      end
    end

    context 'with not started content' do
      before do
        allow(content).to receive(:track_progress).and_return({ completed: 0, total: 7, percentage: 0.0 })
        allow(content).to receive(:completion_status).and_return(:not_started)
      end

      it 'shows not started status' do
        result = render_inline(component)
        expect(result.css('[data-completion-status="not_started"]')).to be_present
        expect(result.css('[data-status="not_started"]')).to be_present
      end
    end
  end

  describe 'responsive design' do
    subject { render_inline(component) }

    it 'includes responsive classes' do
      expect(subject.css('.flex')).to be_present
      expect(subject.css('.gap-1, .gap-2')).to be_present
    end
  end

  describe 'helper methods' do
    describe '#artwork_thumbnail_url' do
      context 'when artwork has image' do
        let(:artwork) { create(:artwork, content: content) }

        before do
          allow(content).to receive(:artwork).and_return(artwork)
          allow(artwork).to receive_message_chain(:image, :present?).and_return(true)
          allow(artwork).to receive_message_chain(:image, :url).and_return('/uploads/artwork.jpg')
        end

        it 'returns artwork image URL' do
          expect(component.send(:artwork_thumbnail_url)).to eq('/uploads/artwork.jpg')
        end
      end

      context 'when artwork has no image' do
        let(:artwork) { create(:artwork, content: content) }

        before do
          allow(content).to receive(:artwork).and_return(artwork)
          allow(artwork).to receive_message_chain(:image, :present?).and_return(false)
        end

        it 'returns nil' do
          expect(component.send(:artwork_thumbnail_url)).to be_nil
        end
      end

      context 'when no artwork exists' do
        before do
          allow(content).to receive(:artwork).and_return(nil)
        end

        it 'returns nil' do
          expect(component.send(:artwork_thumbnail_url)).to be_nil
        end
      end
    end

    describe '#tracks_complete_icon_class' do
      context 'when tracks are complete' do
        before do
          allow(content).to receive(:tracks_complete?).and_return(true)
        end

        it 'returns green color class' do
          expect(component.send(:tracks_complete_icon_class)).to eq('text-green-500')
        end
      end

      context 'when tracks are incomplete' do
        before do
          allow(content).to receive(:tracks_complete?).and_return(false)
        end

        it 'returns gray color class' do
          expect(component.send(:tracks_complete_icon_class)).to eq('text-gray-500')
        end
      end
    end

    describe '#video_generated_icon_class' do
      context 'when video is generated' do
        before do
          allow(content).to receive(:video_generated?).and_return(true)
        end

        it 'returns green color class' do
          expect(component.send(:video_generated_icon_class)).to eq('text-green-500')
        end
      end

      context 'when video is not generated' do
        before do
          allow(content).to receive(:video_generated?).and_return(false)
        end

        it 'returns gray color class' do
          expect(component.send(:video_generated_icon_class)).to eq('text-gray-500')
        end
      end
    end

    describe '#formatted_duration' do
      it 'formats duration in minutes' do
        expect(component.send(:formatted_duration)).to eq('12分')
      end

      context 'with different durations' do
        let(:content) { create(:content, duration_min: 60) }

        it 'formats larger durations' do
          expect(component.send(:formatted_duration)).to eq('60分')
        end
      end
    end
  end
end
