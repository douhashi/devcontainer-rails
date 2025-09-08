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
      expect(subject.text).to include('Chill beats for studying')
    end

    it 'includes data attributes for filtering' do
      expect(subject.css('[data-content-id]')).to be_present
      expect(subject.css('[data-completion-status="in_progress"]')).to be_present
    end

    it 'displays track progress bar' do
      expect(subject.css('[data-percentage]')).to be_present
      expect(subject.text).to include('トラック進捗')
      expect(subject.text).to include('3/7')
    end

    it 'displays artwork status icon' do
      expect(subject.css('.artwork-status')).to be_present
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

      it 'shows completed progress bar' do
        result = render_inline(component)
        expect(result.text).to include('7/7')
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
end
