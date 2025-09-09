require 'rails_helper'

RSpec.describe StatusBadge::Component, type: :component do
  let(:status) { :completed }
  let(:component) { described_class.new(status: status) }

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders badge with correct status' do
      expect(subject.css('span[data-status="completed"]')).to be_present
    end

    it 'displays status text in Japanese' do
      expect(subject.text).to include('完了')
    end

    context 'with completed status' do
      let(:status) { :completed }

      it 'displays completed text' do
        expect(subject.text).to include('完了')
      end

      it 'applies success color classes' do
        expect(subject.to_html).to include('bg-green-100')
        expect(subject.to_html).to include('text-green-800')
      end
    end

    context 'with in_progress status' do
      let(:status) { :in_progress }

      it 'displays in progress text' do
        expect(subject.text).to include('制作中')
      end

      it 'applies warning color classes' do
        expect(subject.to_html).to include('bg-yellow-100')
        expect(subject.to_html).to include('text-yellow-800')
      end
    end

    context 'with needs_attention status' do
      let(:status) { :needs_attention }

      it 'displays needs attention text' do
        expect(subject.text).to include('要対応')
      end

      it 'applies danger color classes' do
        expect(subject.to_html).to include('bg-red-100')
        expect(subject.to_html).to include('text-red-800')
      end
    end

    context 'with not_started status' do
      let(:status) { :not_started }

      it 'displays not started text' do
        expect(subject.text).to include('未着手')
      end

      it 'applies neutral color classes' do
        expect(subject.to_html).to include('bg-gray-100')
        expect(subject.to_html).to include('text-gray-800')
      end
    end

    context 'with audio statuses' do
      context 'with pending status' do
        let(:status) { :pending }

        it 'displays pending text' do
          expect(subject.text).to include('未作成')
        end

        it 'applies gray color classes' do
          expect(subject.to_html).to include('bg-gray-100')
          expect(subject.to_html).to include('text-gray-600')
        end
      end

      context 'with processing status' do
        let(:status) { :processing }

        it 'displays processing text' do
          expect(subject.text).to include('作成中')
        end

        it 'applies blue color classes with animation' do
          expect(subject.to_html).to include('bg-blue-100')
          expect(subject.to_html).to include('text-blue-800')
          expect(subject.to_html).to include('animate-pulse')
        end
      end

      context 'with completed status for audio' do
        let(:status) { :completed }

        it 'displays completed text' do
          expect(subject.text).to include('完了')
        end

        it 'applies green color classes' do
          expect(subject.to_html).to include('bg-green-100')
          expect(subject.to_html).to include('text-green-800')
        end
      end

      context 'with failed status' do
        let(:status) { :failed }

        it 'displays failed text' do
          expect(subject.text).to include('失敗')
        end

        it 'applies red color classes' do
          expect(subject.to_html).to include('bg-red-100')
          expect(subject.to_html).to include('text-red-800')
        end
      end
    end
  end

  describe 'size variants' do
    context 'with small size' do
      let(:component) { described_class.new(status: status, size: :small) }

      it 'applies small size classes' do
        result = render_inline(component)
        expect(result.to_html).to include('text-xs')
        expect(result.to_html).to include('px-2')
        expect(result.to_html).to include('py-1')
      end
    end

    context 'with medium size (default)' do
      it 'applies medium size classes' do
        result = render_inline(component)
        expect(result.to_html).to include('text-sm')
        expect(result.to_html).to include('px-3')
        expect(result.to_html).to include('py-1')
      end
    end

    context 'with large size' do
      let(:component) { described_class.new(status: status, size: :large) }

      it 'applies large size classes' do
        result = render_inline(component)
        expect(result.to_html).to include('text-base')
        expect(result.to_html).to include('px-4')
        expect(result.to_html).to include('py-2')
      end
    end
  end

  describe 'with custom class' do
    let(:component) { described_class.new(status: status, class: "custom-class") }

    it 'includes custom class' do
      result = render_inline(component)
      expect(result.to_html).to include('custom-class')
    end
  end
end
