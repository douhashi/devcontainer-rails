require 'rails_helper'

RSpec.describe AudioGenerationButton::Component, type: :component do
  let(:content) { create(:content, duration_min: 10) }
  let(:component) { described_class.new(content_record: content) }

  describe 'initialization' do
    it 'sets content_record' do
      expect(component.content_record).to eq(content)
    end
  end

  # Rendering tests are simplified to focus on core functionality
  describe 'component methods' do
    it 'can be rendered without error' do
      expect { render_inline(component) }.not_to raise_error
    end
  end

  describe 'private methods' do
    let!(:artwork) { create(:artwork, content: content) }
    let!(:completed_track1) { create(:track, content: content, status: :completed, duration_sec: 180) }
    let!(:completed_track2) { create(:track, content: content, status: :completed, duration_sec: 150) }

    describe '#can_generate_audio?' do
      context 'with all prerequisites' do
        it 'returns true' do
          expect(component.send(:can_generate_audio?)).to be true
        end
      end

      context 'without artwork' do
        before { artwork.destroy! }

        it 'returns false' do
          content.reload
          component = described_class.new(content_record: content)
          expect(component.send(:can_generate_audio?)).to be false
        end
      end

      context 'without completed tracks' do
        before { content.tracks.update_all(status: :pending) }

        it 'returns false' do
          content.reload
          component = described_class.new(content_record: content)
          expect(component.send(:can_generate_audio?)).to be false
        end
      end

      context 'with insufficient tracks' do
        before { completed_track2.destroy! }

        it 'returns false' do
          content.reload
          component = described_class.new(content_record: content)
          expect(component.send(:can_generate_audio?)).to be false
        end
      end
    end

    describe '#audio_exists?' do
      context 'with audio' do
        let!(:audio) { create(:audio, content: content) }

        it 'returns true' do
          expect(component.send(:audio_exists?)).to be true
        end
      end

      context 'without audio' do
        it 'returns false or nil' do
          result = component.send(:audio_exists?)
          expect(result).to be_falsy
        end
      end
    end

    describe '#button_text' do
      context 'without audio' do
        it 'returns default text' do
          expect(component.send(:button_text)).to eq('音源を生成')
        end
      end

      context 'with different audio statuses' do
        let!(:audio) { create(:audio, content: content, status: status) }

        context 'pending' do
          let(:status) { :pending }
          it { expect(component.send(:button_text)).to eq('音源生成待機中...') }
        end

        context 'processing' do
          let(:status) { :processing }
          it { expect(component.send(:button_text)).to eq('音源生成中...') }
        end

        context 'completed' do
          let(:status) { :completed }
          it { expect(component.send(:button_text)).to eq('音源を再生成') }
        end

        context 'failed' do
          let(:status) { :failed }
          it { expect(component.send(:button_text)).to eq('音源生成をリトライ') }
        end
      end
    end

    describe '#prerequisite_errors' do
      context 'with missing artwork and tracks' do
        let(:component_without_prereqs) { described_class.new(content_record: create(:content)) }

        it 'returns multiple errors' do
          errors = component_without_prereqs.send(:prerequisite_errors)
          expect(errors).to include('完成したトラックが必要です')
          expect(errors).to include('アートワークの設定が必要です')
          expect(errors.any? { |e| e.include?('最低2つの完成したトラックが必要です') }).to be true
        end
      end

      context 'with all prerequisites met' do
        it 'returns empty array' do
          errors = component.send(:prerequisite_errors)
          expect(errors).to be_empty
        end
      end
    end
  end
end
