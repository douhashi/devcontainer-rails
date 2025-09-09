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
      expect(subject.text).to include('12 分')  # スペースが追加されたため
      expect(subject.text).to include('Chill beats for studying')
      expect(subject.text).to include('一覧に戻る')
    end

    it 'does not display complex status summary section' do
      expect(subject.css('.status-overview')).not_to be_present
      expect(subject.text).not_to include('制作ステータス')
    end

    it 'shows music generation list' do
      result = render_inline(component)
      expect(result.css('.music-generations-section')).to be_present
      expect(result.text).to include('音楽生成リクエスト')
    end

    it 'does not show Track Counter section' do
      expect(subject.text).not_to include('Track Counter')
    end

    it 'does not show BGM generation section' do
      expect(subject.text).not_to include('BGM生成')
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

    it 'displays theme prominently' do
      expect(subject.css('h1').text).to include('Study Music')
    end

    it 'displays audio prompt clearly' do
      expect(subject.css('.bg-gray-900').text).to include('Chill beats for studying')
    end

    it 'shows creation and update dates' do
      expect(subject.text).to include('作成日時')
      expect(subject.text).to include('更新日時')
    end

    it 'renders sections in correct order' do
      html = subject.to_html
      music_generation_pos = html.index('音楽生成リクエスト')
      artwork_pos = html.index('アートワーク')
      audio_generation_pos = html.index('音源生成')
      video_generation_pos = html.index('動画生成')

      # 音楽生成リクエストがアートワークより前に配置
      expect(music_generation_pos).to be < artwork_pos
      # アートワークが音源生成より前に配置
      expect(artwork_pos).to be < audio_generation_pos
      # 音源生成が動画生成より前に配置
      expect(audio_generation_pos).to be < video_generation_pos
    end

    it 'shows Track Generation Controls in music generation section' do
      expect(subject.css('.music-generations-section').text).to include('Track Generation Controls')
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

      it 'does not show complex status message' do
        result = render_inline(component)
        expect(result.text).not_to include('すべての作業が完了しました！この楽曲は準備完了です。')
      end

      it 'does not show next actions when everything is complete' do
        result = render_inline(component)
        expect(result.css('.next-actions')).not_to be_present
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

  describe 'simplified interface' do
    subject { render_inline(component) }

    it 'does not render complex progress charts' do
      expect(subject.css('.progress-circle')).not_to be_present
    end

    it 'does not show detailed track status breakdown' do
      expect(subject.css('.track-status-item')).not_to be_present
    end

    it 'does not show progress bars' do
      expect(subject.text).not_to include('生成回数')
      expect(subject.text).not_to include('トラック数')
      expect(subject.text).not_to include('3/7曲')
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
