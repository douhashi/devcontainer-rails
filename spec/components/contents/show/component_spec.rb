require 'rails_helper'

RSpec.describe Contents::Show::Component, type: :component do
  let(:content) { create(:content, theme: 'Study Music', duration_min: 12, audio_prompt: 'Chill beats for studying') }
  let(:component) { described_class.new(item: content) }

  before do
    # Mock status methods for content
    allow(content).to receive(:track_progress).and_return({ completed: 3, total: 7, percentage: 42.9 })
    allow(content).to receive(:artwork_status).and_return(:not_configured)
    allow(content).to receive(:completion_status).and_return(:in_progress)
    # next_actions is no longer needed

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

    it 'displays work overview section combining prompt and basic info' do
      expect(subject.text).to include('作品概要')
      # Section should contain both prompt and basic info
      work_overview_section = subject.css('.work-overview-section')
      expect(work_overview_section).to be_present
      expect(work_overview_section.text).to include('Chill beats for studying')
      expect(work_overview_section.text).to include('12 分')
      expect(work_overview_section.text).to include('作成日時')
      expect(work_overview_section.text).to include('更新日時')
    end

    it 'does not show next actions recommendations' do
      expect(subject.css('.next-actions')).not_to be_present
      expect(subject.text).not_to include('推奨アクション')
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
      header_pos = html.index('Study Music')
      prompt_pos = html.index('音楽生成プロンプト')
      edit_button_pos = html.index('編集')
      artwork_pos = html.index('アートワーク')
      music_generation_pos = html.index('音楽生成リクエスト')
      audio_generation_pos = html.index('音源生成')
      video_generation_pos = html.index('動画生成')

      # 作品概要（プロンプト）がヘッダーの後に配置
      expect(prompt_pos).to be > header_pos
      # 編集ボタンが作品概要の後、アートワークの前に配置
      expect(edit_button_pos).to be > prompt_pos
      expect(edit_button_pos).to be < artwork_pos
      # アートワークが編集ボタンの後に配置
      expect(artwork_pos).to be > edit_button_pos
      # 音楽生成リクエストがアートワークの後に配置
      expect(music_generation_pos).to be > artwork_pos
      # 音源生成が音楽生成リクエストの後に配置
      expect(audio_generation_pos).to be > music_generation_pos
      # 動画生成が音源生成の後に配置
      expect(video_generation_pos).to be > audio_generation_pos
    end

    it 'shows Track Generation Controls in music generation section' do
      expect(subject.css('.music-generations-section').text).to include('Track Generation Controls')
    end

    context 'with completed content' do
      before do
        allow(content).to receive(:track_progress).and_return({ completed: 7, total: 7, percentage: 100.0 })
        allow(content).to receive(:artwork_status).and_return(:configured)
        allow(content).to receive(:completion_status).and_return(:completed)
        # next_actions is no longer needed
      end

      it 'shows completed status' do
        result = render_inline(component)
        expect(result.css('[data-status="completed"]')).to be_present
      end

      it 'does not show complex status message' do
        result = render_inline(component)
        expect(result.text).not_to include('すべての作業が完了しました！この楽曲は準備完了です。')
      end

      it 'does not show next actions section' do
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

  describe 'section-based layout' do
    subject { render_inline(component) }

    it 'has independent card sections with proper styling' do
      # Each section should have its own bg-gray-800 rounded-lg card
      cards = subject.css('.bg-gray-800.rounded-lg')
      # Should have at least 5 independent sections (excluding nested artwork section)
      expect(cards.size).to be >= 5
    end

    it 'has proper spacing between sections' do
      # Check that sections have mb-6 spacing (except the last one)
      sections_with_spacing = subject.css('.bg-gray-800.rounded-lg.mb-6')
      expect(sections_with_spacing.size).to be >= 4
    end

    it 'has content overview as first card section' do
      cards = subject.css('.bg-gray-800.rounded-lg')
      first_card = cards.first
      expect(first_card.text).to include('Study Music')
      expect(first_card.css('.text-3xl').text).to include('Study Music')
    end

    it 'has artwork as second independent card section' do
      cards = subject.css('.bg-gray-800.rounded-lg')
      # The second card should be artwork
      artwork_card = cards[1]
      expect(artwork_card).to be_present
      expect(artwork_card.text).to include('アートワーク')
    end

    it 'has music generation request as independent card section' do
      # Check for music generation section as independent card
      music_gen_cards = subject.css('.bg-gray-800.rounded-lg').select { |card|
        card.text.include?('音楽生成リクエスト')
      }
      expect(music_gen_cards).not_to be_empty
    end

    it 'has audio generation as independent card section' do
      audio_gen_cards = subject.css('.bg-gray-800.rounded-lg').select { |card|
        card.text.include?('音源生成')
      }
      expect(audio_gen_cards).not_to be_empty
    end

    it 'has video generation as independent card section' do
      video_gen_cards = subject.css('.bg-gray-800.rounded-lg').select { |card|
        card.text.include?('動画生成')
      }
      expect(video_gen_cards).not_to be_empty
    end
  end

  describe 'icon buttons' do
    subject { render_inline(component) }

    it 'renders edit button as icon button with correct attributes' do
      # Check for icon button structure
      edit_button = subject.css('a[href*="edit"]').first
      expect(edit_button).to be_present

      # Check for icon component
      expect(edit_button.css('i.fa-pen-to-square')).to be_present

      # Check for aria-label
      expect(edit_button['aria-label']).to eq('編集')

      # Check for variant styling
      expect(edit_button['class']).to include('bg-blue-600')
    end

    it 'renders delete button as icon button with correct attributes' do
      # Check for icon button structure
      delete_button = subject.css('a[data-turbo-method="delete"]').first
      expect(delete_button).to be_present

      # Check for icon component
      expect(delete_button.css('i.fa-trash')).to be_present

      # Check for aria-label
      expect(delete_button['aria-label']).to eq('削除')

      # Check for variant styling
      expect(delete_button['class']).to include('bg-red-600')

      # Check for delete confirmation controller
      expect(delete_button['data-controller']).to include('delete-confirmation')
      expect(delete_button['data-action']).to include('click->delete-confirmation#confirm')
      expect(delete_button['data-delete-confirmation-message-value']).to eq('本当に削除しますか？')
    end

    it 'maintains proper button sizing' do
      edit_button = subject.css('a[href*="edit"]').first
      delete_button = subject.css('a[data-turbo-method="delete"]').first

      # Check for consistent size styling
      expect(edit_button['class']).to include('px-4', 'py-2')
      expect(delete_button['class']).to include('px-4', 'py-2')
    end

    it 'keeps hover effects on icon buttons' do
      edit_button = subject.css('a[href*="edit"]').first
      delete_button = subject.css('a[data-turbo-method="delete"]').first

      # Check for hover styling
      expect(edit_button['class']).to include('hover:bg-blue-700')
      expect(delete_button['class']).to include('hover:bg-red-700')
    end
  end
end
