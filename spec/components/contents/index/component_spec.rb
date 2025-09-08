require 'rails_helper'

RSpec.describe Contents::Index::Component, type: :component do
  let(:content1) { create(:content, theme: 'Study Music', duration_min: 12) }
  let(:content2) { create(:content, theme: 'Work Music', duration_min: 30) }
  let(:contents) { [ content1, content2 ] }
  let(:component) { described_class.new(contents: contents, filter_status: filter_status) }
  let(:filter_status) { nil }

  before do
    # Mock status methods for contents
    allow(content1).to receive(:track_progress).and_return({ completed: 3, total: 7, percentage: 42.9 })
    allow(content1).to receive(:artwork_status).and_return(:not_configured)
    allow(content1).to receive(:completion_status).and_return(:in_progress)

    allow(content2).to receive(:track_progress).and_return({ completed: 10, total: 10, percentage: 100.0 })
    allow(content2).to receive(:artwork_status).and_return(:configured)
    allow(content2).to receive(:completion_status).and_return(:completed)
  end

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders page header with title and new content link' do
      expect(subject.text).to include('コンテンツ一覧')
      expect(subject.text).to include('新規作成')
      expect(subject.css('a[href*="new"]')).to be_present
    end

    it 'renders status filter component' do
      expect(subject.css('[data-controller="status-filter"]')).to be_present
    end

    it 'renders content cards' do
      expect(subject.css('[data-testid="content-card"]').size).to eq(2)
      expect(subject.text).to include('Study Music')
      expect(subject.text).to include('Work Music')
    end

    it 'displays filter status summary' do
      expect(subject.css('.filter-summary')).to be_present
      expect(subject.text).to include('2件のコンテンツ')
    end

    context 'with empty contents' do
      let(:contents) { [] }

      it 'displays empty state' do
        expect(subject.text).to include('コンテンツがまだありません')
        expect(subject.text).to include('最初のコンテンツを作成')
      end

      it 'does not render status filter when empty' do
        expect(subject.css('[data-controller="status-filter"]')).not_to be_present
      end

      it 'does not render filter summary when empty' do
        expect(subject.css('.filter-summary')).not_to be_present
      end
    end

    context 'with filter status selected' do
      let(:filter_status) { 'completed' }

      it 'passes filter status to StatusFilter component' do
        expect(subject.css('[data-status-filter-selected-value="completed"]')).to be_present
      end
    end

    context 'with paginated contents' do
      let(:paginated_contents) { double('paginated_contents') }
      let(:component) { described_class.new(contents: paginated_contents, filter_status: filter_status) }

      before do
        allow(paginated_contents).to receive(:empty?).and_return(false)
        allow(paginated_contents).to receive(:size).and_return(2)
        allow(paginated_contents).to receive(:each).and_yield(content1).and_yield(content2)
        allow(paginated_contents).to receive(:current_page).and_return(1)
        allow(paginated_contents).to receive(:total_pages).and_return(3)
        allow(paginated_contents).to receive(:respond_to?).with(:current_page).and_return(true)
      end

      it 'shows pagination section' do
        result = render_inline(component)
        expect(result.css('[data-testid="pagination"]')).to be_present
      end
    end
  end

  describe 'status summary' do
    subject { render_inline(component) }

    it 'calculates and displays status counts' do
      expect(subject.text).to include('制作中: 1件')
      expect(subject.text).to include('完了: 1件')
    end
  end

  describe 'responsive grid layout' do
    subject { render_inline(component) }

    it 'uses responsive grid classes' do
      expect(subject.css('.grid-cols-1')).to be_present
      expect(subject.css('.md\\:grid-cols-2')).to be_present
      expect(subject.css('.lg\\:grid-cols-3')).to be_present
    end
  end
end
