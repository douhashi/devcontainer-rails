# frozen_string_literal: true

require "rails_helper"

RSpec.describe VideoGenerationButton::Component, type: :component do
  include ViewComponent::TestHelpers
  include ViewComponent::SystemTestHelpers
  let(:content_record) { create(:content) }
  let(:component) { VideoGenerationButton::Component.new(content_record: content_record) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end

  describe 'private methods' do
    let!(:artwork) { create(:artwork, content: content_record) }
    let!(:audio) { create(:audio, content: content_record, status: :completed) }

    describe '#can_generate_video?' do
      before do
        allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(true)
      end

      it 'delegates to content_record' do
        expect(component.send(:can_generate_video?)).to be true
      end
    end

    describe '#button_text' do
      context 'without video' do
        it 'returns default text' do
          expect(component.send(:button_text)).to eq('動画を生成')
        end
      end

      context 'with different video statuses' do
        let!(:video) { create(:video, content: content_record, status: status) }

        context 'pending' do
          let(:status) { :pending }
          it { expect(component.send(:button_text)).to eq('動画生成待機中...') }
        end

        context 'processing' do
          let(:status) { :processing }
          it { expect(component.send(:button_text)).to eq('動画生成中...') }
        end

        context 'completed' do
          let(:status) { :completed }
          it { expect(component.send(:button_text)).to eq('動画を再生成') }
        end

        context 'failed' do
          let(:status) { :failed }
          it { expect(component.send(:button_text)).to eq('動画生成をリトライ') }
        end
      end
    end

    describe '#tooltip_text' do
      context 'when prerequisites are not met' do
        before do
          allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(false)
          allow(content_record).to receive(:video_generation_missing_prerequisites).and_return([ '音源が必要です' ])
        end

        it 'returns concatenated error messages' do
          tooltip = component.send(:tooltip_text)
          expect(tooltip).to eq('音源が必要です')
        end
      end

      context 'when all prerequisites are met' do
        before do
          allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(true)
          allow(content_record).to receive(:video_generation_missing_prerequisites).and_return([])
        end

        it 'returns nil' do
          tooltip = component.send(:tooltip_text)
          expect(tooltip).to be_nil
        end
      end
    end

    describe '#button_attributes' do
      context 'when disabled' do
        before do
          allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(false)
          allow(content_record).to receive(:video_generation_missing_prerequisites).and_return([ '音源が必要です' ])
        end

        it 'includes disabled attribute and tooltip' do
          attrs = component.send(:button_attributes)
          expect(attrs[:disabled]).to be true
          expect(attrs[:title]).to be_present
        end
      end

      context 'when enabled' do
        before do
          allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(true)
          allow(content_record).to receive(:video_generation_missing_prerequisites).and_return([])
        end

        it 'does not include disabled attribute' do
          attrs = component.send(:button_attributes)
          expect(attrs[:disabled]).to be false
          expect(attrs[:title]).to be_nil
        end
      end
    end
  end
end
