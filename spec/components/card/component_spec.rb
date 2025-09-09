require 'rails_helper'

RSpec.describe Card::Component, type: :component do
  let(:component) { described_class.new }

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders a div with basic card classes' do
      expect(subject.css('div').first['class']).to include('bg-gray-800')
      expect(subject.css('div').first['class']).to include('rounded-lg')
    end

    context 'with default options' do
      it 'applies default variant classes' do
        expect(subject.to_html).to include('bg-gray-800')
      end

      it 'applies default padding classes' do
        expect(subject.to_html).to include('p-6')
      end
    end

    context 'with title option' do
      let(:component) { described_class.new(title: "Test Card Title") }

      it 'displays the title in header' do
        expect(subject.text).to include('Test Card Title')
      end

      it 'renders title with correct classes' do
        expect(subject.to_html).to include('text-xl font-bold text-gray-100')
      end
    end

    context 'without title option' do
      let(:component) { described_class.new }

      it 'does not render header section' do
        expect(subject.css('.card-header')).to be_empty
      end
    end

    context 'with block content' do
      it 'renders block content in body' do
        result = render_inline(component) { "Test content" }
        expect(result.text).to include('Test content')
      end
    end
  end

  describe 'variant options' do
    context 'with default variant' do
      let(:component) { described_class.new(variant: :default) }

      it 'applies default variant classes' do
        expect(render_inline(component).to_html).to include('bg-gray-800')
      end
    end

    context 'with bordered variant' do
      let(:component) { described_class.new(variant: :bordered) }

      it 'applies bordered variant classes' do
        result = render_inline(component)
        expect(result.to_html).to include('bg-gray-800')
        expect(result.to_html).to include('border')
        expect(result.to_html).to include('border-gray-600')
      end
    end

    context 'with elevated variant' do
      let(:component) { described_class.new(variant: :elevated) }

      it 'applies elevated variant classes' do
        result = render_inline(component)
        expect(result.to_html).to include('bg-gray-800')
        expect(result.to_html).to include('shadow-lg')
        expect(result.to_html).to include('shadow-gray-900/30')
      end
    end

    context 'with invalid variant' do
      let(:component) { described_class.new(variant: :invalid) }

      it 'falls back to default variant' do
        expect(render_inline(component).to_html).to include('bg-gray-800')
      end
    end
  end

  describe 'padding options' do
    context 'with small padding' do
      let(:component) { described_class.new(padding: :sm) }

      it 'applies small padding classes' do
        expect(render_inline(component).to_html).to include('p-4')
      end
    end

    context 'with medium padding (default)' do
      let(:component) { described_class.new(padding: :md) }

      it 'applies medium padding classes' do
        expect(render_inline(component).to_html).to include('p-6')
      end
    end

    context 'with large padding' do
      let(:component) { described_class.new(padding: :lg) }

      it 'applies large padding classes' do
        expect(render_inline(component).to_html).to include('p-8')
      end
    end

    context 'with invalid padding' do
      let(:component) { described_class.new(padding: :invalid) }

      it 'falls back to default padding' do
        expect(render_inline(component).to_html).to include('p-6')
      end
    end
  end

  describe 'custom class option' do
    let(:component) { described_class.new(class: "custom-class") }

    it 'includes custom class' do
      result = render_inline(component)
      expect(result.to_html).to include('custom-class')
    end
  end

  describe 'slots functionality' do
    context 'with header slot' do
      it 'renders header slot content' do
        result = render_inline(described_class.new) do |component|
          component.with_header { "Custom Header Content" }
        end
        expect(result.text).to include('Custom Header Content')
      end
    end

    context 'with footer slot' do
      it 'renders footer slot content' do
        result = render_inline(described_class.new) do |component|
          component.with_footer { "Custom Footer Content" }
        end
        expect(result.text).to include('Custom Footer Content')
      end
    end

    context 'with actions slot' do
      it 'renders actions slot content' do
        result = render_inline(described_class.new) do |component|
          component.with_actions { "Action Buttons" }
        end
        expect(result.text).to include('Action Buttons')
      end
    end

    context 'with multiple slots' do
      it 'renders all slot contents in correct positions' do
        result = render_inline(described_class.new) do |component|
          component.with_header { "Header" }
          component.with_footer { "Footer" }
          "Body Content"
        end
        html = result.to_html
        expect(html).to include('Header')
        expect(html).to include('Footer')
        expect(html).to include('Body Content')
      end
    end
  end

  describe 'css_classes method' do
    it 'combines all classes correctly' do
      component = described_class.new(
        variant: :bordered,
        padding: :lg,
        class: "custom"
      )

      classes = component.send(:css_classes)
      expect(classes).to include('bg-gray-800')
      expect(classes).to include('rounded-lg')
      expect(classes).to include('border')
      expect(classes).to include('p-8')
      expect(classes).to include('custom')
    end
  end
end
