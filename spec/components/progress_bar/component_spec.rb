require 'rails_helper'

RSpec.describe ProgressBar::Component, type: :component do
  let(:percentage) { 75.0 }
  let(:component) { described_class.new(percentage: percentage) }

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders progress bar with correct percentage' do
      expect(subject.css('div[data-percentage="75.0"]')).to be_present
    end

    it 'renders progress bar with width style' do
      expect(subject.css('div[style*="width: 75.0%"]')).to be_present
    end

    it 'includes percentage text' do
      expect(subject.text).to include('75.0%')
    end

    context 'with custom label' do
      let(:component) { described_class.new(percentage: percentage, label: 'トラック進捗') }

      it 'displays custom label' do
        expect(subject.text).to include('トラック進捗')
      end
    end

    context 'with zero percentage' do
      let(:percentage) { 0.0 }

      it 'renders with zero width' do
        expect(subject.to_html).to include('data-percentage="0"')
        expect(subject.to_html).to include('width: 0%')
      end
    end

    context 'with 100% percentage' do
      let(:percentage) { 100.0 }

      it 'renders with full width' do
        expect(subject.css('div[style*="width: 100.0%"]')).to be_present
      end
    end
  end

  describe 'color variants' do
    context 'with default variant' do
      it 'applies primary color class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('bg-blue-500')
      end
    end

    context 'with success variant' do
      let(:component) { described_class.new(percentage: percentage, variant: :success) }

      it 'applies success color class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('bg-green-500')
      end
    end

    context 'with warning variant' do
      let(:component) { described_class.new(percentage: percentage, variant: :warning) }

      it 'applies warning color class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('bg-yellow-500')
      end
    end

    context 'with danger variant' do
      let(:component) { described_class.new(percentage: percentage, variant: :danger) }

      it 'applies danger color class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('bg-red-500')
      end
    end
  end

  describe 'size variants' do
    context 'with small size' do
      let(:component) { described_class.new(percentage: percentage, size: :small) }

      it 'applies small height class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('h-2')
      end
    end

    context 'with medium size (default)' do
      it 'applies medium height class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('h-4')
      end
    end

    context 'with large size' do
      let(:component) { described_class.new(percentage: percentage, size: :large) }

      it 'applies large height class' do
        result = render_inline(component)
        expect(result.css('[data-percentage]').first['class']).to include('h-6')
      end
    end
  end
end
