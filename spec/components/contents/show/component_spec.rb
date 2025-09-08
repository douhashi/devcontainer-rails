require 'rails_helper'

RSpec.describe Contents::Show::Component, type: :component do
  let(:content) { create(:content, theme: 'Study Music', duration_min: 12, audio_prompt: 'Chill beats for studying') }
  let(:component) { described_class.new(item: content) }

  before do
    # Mock status methods for content
    allow(content).to receive(:track_progress).and_return({ completed: 3, total: 7, percentage: 42.9 })
    allow(content).to receive(:artwork_status).and_return(:not_configured)
    allow(content).to receive(:completion_status).and_return(:in_progress)
    allow(content).to receive(:next_actions).and_return([ 'トラックを生成してください', 'アートワークを設定してください' ])

    # Mock associated components that may not exist
    stub_const('Artwork::Form::Component', Class.new(ApplicationViewComponent) do
      def initialize(content_record:)
        @content_record = content_record
      end

      def call
        '<div>Artwork Form</div>'.html_safe
      end
    end)

    stub_const('TrackGenerationButtonComponent', Class.new(ApplicationViewComponent) do
      def initialize(content_record:)
        @content_record = content_record
      end

      def call
        '<div>Track Generation Button</div>'.html_safe
      end
    end)

    stub_const('TrackCounter::Component', Class.new(ApplicationViewComponent) do
      def initialize(content_record:, current_count: nil, max_count: 100)
        @content_record = content_record
      end

      def call
        '<div>Track Counter</div>'.html_safe
      end
    end)

    stub_const('TrackGenerationControls::Component', Class.new(ApplicationViewComponent) do
      def initialize(content_record:, can_generate_more: true)
        @content_record = content_record
      end

      def call
        '<div>Track Generation Controls</div>'.html_safe
      end
    end)
  end

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders content details and navigation' do
      expect(subject.text).to include('Study Music')
      expect(subject.text).to include('12分')
      expect(subject.text).to include('Chill beats for studying')
      expect(subject.text).to include('一覧に戻る')
    end

    it 'displays enhanced status summary' do
      expect(subject.css('.status-overview')).to be_present
      expect(subject.text).to include('制作ステータス')
    end

    it 'shows track list when tracks exist' do
      # Simulate that content has tracks
      allow(content.tracks).to receive(:any?).and_return(true)
      result = render_inline(component)
      expect(result.css('.tracks-section')).to be_present
      expect(result.text).to include('トラック一覧')
    end

    it 'displays artwork status with preview' do
      expect(subject.css('.artwork-section')).to be_present
      expect(subject.text).to include('アートワーク')
    end

    it 'shows next actions recommendations' do
      expect(subject.css('.next-actions')).to be_present
      expect(subject.text).to include('推奨アクション')
      expect(subject.text).to include('トラックを生成してください')
      expect(subject.text).to include('アートワークを設定してください')
    end

    it 'includes completion status badge' do
      expect(subject.css('[data-status="in_progress"]')).to be_present
    end

    context 'with completed content' do
      before do
        allow(content).to receive(:track_progress).and_return({ completed: 7, total: 7, percentage: 100.0 })
        allow(content).to receive(:artwork_status).and_return(:configured)
        allow(content).to receive(:completion_status).and_return(:completed)
        allow(content).to receive(:next_actions).and_return([])
      end

      it 'shows completed status' do
        result = render_inline(component)
        expect(result.css('[data-status="completed"]')).to be_present
      end

      it 'shows success message when completed' do
        result = render_inline(component)
        expect(result.text).to include('すべての作業が完了しました')
      end

      it 'hides next actions when everything is complete' do
        result = render_inline(component)
        expect(result.css('.next-actions.hidden')).to be_present
      end
    end

    context 'with content needing attention' do
      before do
        allow(content).to receive(:completion_status).and_return(:needs_attention)
      end

      it 'shows attention needed styling' do
        result = render_inline(component)
        expect(result.css('[data-status="needs_attention"]')).to be_present
      end
    end
  end

  describe 'progress visualization' do
    subject { render_inline(component) }

    it 'renders circular progress chart' do
      expect(subject.css('.progress-circle')).to be_present
    end

    it 'shows track status breakdown with icons' do
      expect(subject.css('.track-status-item')).to be_present
    end

    context 'with MusicGeneration progress' do
      before do
        allow(content).to receive(:music_generation_progress).and_return({
          completed: 1,
          total: 2,
          percentage: 50.0
        })
      end

      it 'shows both MusicGeneration and Track progress' do
        result = render_inline(component)
        expect(result.text).to include('生成回数')
        expect(result.text).to include('1/2回')
        expect(result.text).to include('トラック数')
        expect(result.text).to include('3/7曲')
      end
    end
  end

  describe 'responsive design' do
    subject { render_inline(component) }

    it 'includes responsive grid layouts' do
      expect(subject.css('.grid')).to be_present
      expect(subject.css('.md\\:grid-cols-3')).to be_present
    end
  end
end
