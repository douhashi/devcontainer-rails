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
          it { expect(component.send(:button_text)).to be_nil }
        end

        context 'processing' do
          let(:status) { :processing }
          it { expect(component.send(:button_text)).to be_nil }
        end

        context 'completed' do
          let(:status) { :completed }
          it { expect(component.send(:button_text)).to be_nil }
        end

        context 'failed' do
          let(:status) { :failed }
          it { expect(component.send(:button_text)).to eq('削除') }
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

    describe '#show_delete_button?' do
      context 'when video does not exist' do
        it 'returns false' do
          expect(component.send(:show_delete_button?)).to be false
        end
      end

      context 'when video exists' do
        let!(:video) { create(:video, content: content_record, status: status) }

        context 'with any status' do
          let(:status) { :completed }
          it 'returns false (integrated into main button)' do
            expect(component.send(:show_delete_button?)).to be false
          end
        end
      end
    end

    describe '#delete_button_disabled?' do
      context 'when video does not exist' do
        it 'returns false' do
          expect(component.send(:delete_button_disabled?)).to be false
        end
      end

      context 'when video exists' do
        let!(:video) { create(:video, content: content_record, status: status) }

        context 'with pending status' do
          let(:status) { :pending }
          it 'returns false' do
            expect(component.send(:delete_button_disabled?)).to be false
          end
        end

        context 'with processing status' do
          let(:status) { :processing }
          it 'returns true' do
            expect(component.send(:delete_button_disabled?)).to be true
          end
        end

        context 'with completed status' do
          let(:status) { :completed }
          it 'returns false' do
            expect(component.send(:delete_button_disabled?)).to be false
          end
        end

        context 'with failed status' do
          let(:status) { :failed }
          it 'returns false' do
            expect(component.send(:delete_button_disabled?)).to be false
          end
        end
      end
    end

    describe '#delete_button_classes' do
      let!(:video) { create(:video, content: content_record, status: status) }

      context 'when disabled (processing status)' do
        let(:status) { :processing }
        it 'returns disabled classes' do
          classes = component.send(:delete_button_classes)
          expect(classes).to include('bg-gray-400')
          expect(classes).to include('cursor-not-allowed')
          expect(classes).to include('opacity-50')
        end
      end

      context 'when enabled (completed status)' do
        let(:status) { :completed }
        it 'returns enabled classes' do
          classes = component.send(:delete_button_classes)
          expect(classes).to include('bg-red-600')
          expect(classes).to include('hover:bg-red-700')
          expect(classes).not_to include('cursor-not-allowed')
        end
      end
    end

    describe '#delete_confirmation_message' do
      context 'when video does not exist' do
        it 'returns default message' do
          expect(component.send(:delete_confirmation_message)).to eq('動画を削除しますか？')
        end
      end

      context 'when video exists' do
        let!(:video) { create(:video, content: content_record, status: status) }

        context 'with failed status' do
          let(:status) { :failed }
          it 'returns failed-specific message' do
            expect(component.send(:delete_confirmation_message)).to eq('失敗した動画を削除しますか？')
          end
        end

        context 'with completed status' do
          let(:status) { :completed }
          it 'returns completed-specific message' do
            expect(component.send(:delete_confirmation_message)).to eq('動画を削除しますか？削除後、再生成が可能になります。')
          end
        end

        context 'with other status' do
          let(:status) { :processing }
          it 'returns default message' do
            expect(component.send(:delete_confirmation_message)).to eq('動画を削除しますか？')
          end
        end
      end
    end

    describe '#technical_specs' do
      it 'returns correct technical specifications' do
        specs = component.send(:technical_specs)
        expect(specs).to include(
          video_codec: 'H.264 (libx264)',
          audio_codec: 'AAC (192kbps, 48kHz)',
          frame_rate: '30fps',
          optimization: 'YouTube推奨設定'
        )
      end
    end

    describe '#button_classes' do
      context 'when button shows delete (completed or failed)' do
        let!(:video) { create(:video, content: content_record, status: :completed) }

        it 'returns red button classes' do
          classes = component.send(:button_classes)
          expect(classes).to include('bg-red-600')
          expect(classes).to include('hover:bg-red-700')
        end
      end

      context 'when button shows generate' do
        before do
          allow(content_record).to receive(:video_generation_prerequisites_met?).and_return(true)
        end

        it 'returns green button classes' do
          classes = component.send(:button_classes)
          expect(classes).to include('bg-green-600')
          expect(classes).to include('hover:bg-green-700')
        end
      end
    end
  end
end
