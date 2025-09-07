require 'rails_helper'

RSpec.describe StatusFilter::Component, type: :component do
  let(:selected_status) { nil }
  let(:component) { described_class.new(selected_status: selected_status) }

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders filter container with stimulus controller' do
      expect(subject.css('[data-controller="status-filter"]')).to be_present
    end

    it 'renders all filter options' do
      expect(subject.text).to include('全て')
      expect(subject.text).to include('完了')
      expect(subject.text).to include('制作中')
      expect(subject.text).to include('要対応')
      expect(subject.text).to include('未着手')
    end

    it 'marks "全て" as active by default' do
      expect(subject.css('button[data-status="all"].bg-blue-500')).to be_present
    end

    context 'with selected status' do
      let(:selected_status) { 'completed' }

      it 'marks selected status as active' do
        expect(subject.css('button[data-status="completed"].bg-blue-500')).to be_present
      end

      it 'does not mark "全て" as active' do
        expect(subject.css('button[data-status="all"].bg-gray-200')).to be_present
      end
    end
  end

  describe 'status options' do
    let(:component) { described_class.new }
    let(:rendered) { render_inline(component) }

    it 'includes all status filter buttons' do
      expect(rendered.css('[data-status="all"]')).to be_present
      expect(rendered.css('[data-status="completed"]')).to be_present
      expect(rendered.css('[data-status="in_progress"]')).to be_present
      expect(rendered.css('[data-status="needs_attention"]')).to be_present
      expect(rendered.css('[data-status="not_started"]')).to be_present
    end

    it 'includes data-action attributes for stimulus' do
      expect(rendered.css('[data-action*="status-filter#filter"]')).to be_present
    end
  end
end
