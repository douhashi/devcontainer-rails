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

  describe 'rendering with ButtonComponent' do
    let!(:completed_track1) { create(:track, content: content, status: :completed, duration_sec: 180) }
    let!(:completed_track2) { create(:track, content: content, status: :completed, duration_sec: 150) }

    context 'when can generate audio' do
      it 'renders generate button with ButtonComponent' do
        rendered = render_inline(component)
        expect(rendered.css('button').text).to include('音源を生成')
      end
    end

    context 'when audio is completed' do
      let!(:audio) { create(:audio, content: content, status: :completed) }

      it 'renders delete button with ButtonComponent' do
        rendered = render_inline(component)
        expect(rendered.css('button').text).to include('削除')
      end
    end

    context 'when audio is processing' do
      let!(:audio) { create(:audio, content: content, status: :processing) }

      it 'renders processing button with ButtonComponent' do
        rendered = render_inline(component)
        expect(rendered.css('button').text).to include('作成中')
      end
    end
  end

  describe 'private methods' do
    let!(:completed_track1) { create(:track, content: content, status: :completed, duration_sec: 180) }
    let!(:completed_track2) { create(:track, content: content, status: :completed, duration_sec: 150) }

    describe '#can_generate_audio?' do
      context 'with all prerequisites' do
        it 'returns true' do
          expect(component.send(:can_generate_audio?)).to be true
        end
      end

      context 'without artwork' do
        it 'returns true if tracks requirements are met' do
          # アートワークなしでもトラック条件を満たしていればtrue
          component = described_class.new(content_record: content)
          expect(component.send(:can_generate_audio?)).to be true
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
          it { expect(component.send(:button_text)).to eq('作成中') }
        end

        context 'processing' do
          let(:status) { :processing }
          it { expect(component.send(:button_text)).to eq('作成中') }
        end

        context 'completed' do
          let(:status) { :completed }
          it { expect(component.send(:button_text)).to eq('削除') }
        end

        context 'failed' do
          let(:status) { :failed }
          it { expect(component.send(:button_text)).to eq('削除') }
        end
      end
    end

    describe '#prerequisite_errors' do
      context 'with missing tracks' do
        let(:component_without_prereqs) { described_class.new(content_record: create(:content)) }

        it 'returns track-related errors only' do
          errors = component_without_prereqs.send(:prerequisite_errors)
          expect(errors).to include('トラックが必要')
          expect(errors.any? { |e| e.include?('トラック2個以上必要') }).to be true
          # アートワーク関連のエラーは含まれない
          expect(errors).not_to include('アートワークが必要')
        end
      end

      context 'with all prerequisites met' do
        it 'returns empty array' do
          errors = component.send(:prerequisite_errors)
          expect(errors).to be_empty
        end
      end
    end

    describe '#tooltip_text' do
      context 'when prerequisites are not met' do
        let(:component_without_prereqs) { described_class.new(content_record: create(:content)) }

        it 'returns concatenated error messages' do
          tooltip = component_without_prereqs.send(:tooltip_text)
          expect(tooltip).to include('トラックが必要')
        end
      end

      context 'when all prerequisites are met' do
        it 'returns nil' do
          tooltip = component.send(:tooltip_text)
          expect(tooltip).to be_nil
        end
      end
    end

    describe '#button_attributes' do
      context 'when disabled' do
        let(:component_without_prereqs) { described_class.new(content_record: create(:content)) }

        it 'includes disabled attribute and tooltip' do
          attrs = component_without_prereqs.send(:button_attributes)
          expect(attrs[:disabled]).to be true
          expect(attrs[:title]).to be_present
        end
      end

      context 'when enabled' do
        it 'does not include disabled attribute' do
          attrs = component.send(:button_attributes)
          expect(attrs[:disabled]).to be false
          expect(attrs[:title]).to be_nil
        end
      end
    end

    describe '#show_delete_button?' do
      context 'when audio does not exist' do
        it 'returns false' do
          expect(component.send(:show_delete_button?)).to be false
        end
      end

      context 'when audio exists' do
        let!(:audio) { create(:audio, content: content, status: status) }

        context 'with pending status' do
          let(:status) { :pending }
          it 'returns false' do
            expect(component.send(:show_delete_button?)).to be false
          end
        end

        context 'with processing status' do
          let(:status) { :processing }
          it 'returns false' do
            expect(component.send(:show_delete_button?)).to be false
          end
        end

        context 'with completed status' do
          let(:status) { :completed }
          it 'returns false' do
            expect(component.send(:show_delete_button?)).to be false
          end
        end

        context 'with failed status' do
          let(:status) { :failed }
          it 'returns false' do
            expect(component.send(:show_delete_button?)).to be false
          end
        end
      end
    end

    describe '#delete_button_disabled?' do
      context 'when audio does not exist' do
        it 'returns false' do
          expect(component.send(:delete_button_disabled?)).to be false
        end
      end

      context 'when audio exists' do
        let!(:audio) { create(:audio, content: content, status: status) }

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
      let!(:audio) { create(:audio, content: content, status: status) }

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
      context 'when audio does not exist' do
        it 'returns default message' do
          expect(component.send(:delete_confirmation_message)).to eq('音源を削除しますか？')
        end
      end

      context 'when audio exists' do
        let!(:audio) { create(:audio, content: content, status: status) }

        context 'with failed status' do
          let(:status) { :failed }
          it 'returns failed-specific message' do
            expect(component.send(:delete_confirmation_message)).to eq('失敗した音源を削除しますか？')
          end
        end

        context 'with completed status' do
          let(:status) { :completed }
          it 'returns completed-specific message' do
            expect(component.send(:delete_confirmation_message)).to eq('音源を削除しますか？削除後、再生成が可能になります。')
          end
        end

        context 'with other status' do
          let(:status) { :processing }
          it 'returns default message' do
            expect(component.send(:delete_confirmation_message)).to eq('音源を削除しますか？')
          end
        end
      end
    end
  end
end
