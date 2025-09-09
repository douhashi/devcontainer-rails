# frozen_string_literal: true

require "rails_helper"

RSpec.describe Icon::Component, type: :component do
  subject(:component) { described_class.new(**params) }

  describe "initialization" do
    context "with required parameters" do
      let(:params) { { name: :image } }

      it "creates component successfully" do
        expect(component).to be_a(described_class)
      end

      it "sets default size to :md" do
        expect(component.size).to eq(:md)
      end

      it "sets default color to nil" do
        expect(component.color).to be_nil
      end
    end

    context "with all parameters" do
      let(:params) { { name: :music, size: :lg, color: "text-blue-500", aria_label: "Music icon" } }

      it "sets all attributes correctly" do
        expect(component.name).to eq(:music)
        expect(component.size).to eq(:lg)
        expect(component.color).to eq("text-blue-500")
        expect(component.aria_label).to eq("Music icon")
      end
    end
  end

  describe "#render" do
    context "with basic icon" do
      let(:params) { { name: :image } }

      it "renders SVG element" do
        render_inline(component)
        expect(page).to have_css("svg")
      end

      it "applies correct viewBox" do
        render_inline(component)
        expect(page).to have_css('svg[viewbox="0 0 24 24"]')
      end

      it "applies stroke properties" do
        render_inline(component)
        expect(page).to have_css('svg[stroke="currentColor"]')
        expect(page).to have_css('svg[stroke-width="1.5"]')
        expect(page).to have_css('svg[fill="none"]')
      end
    end

    context "with different sizes" do
      it "applies small size classes" do
        component = described_class.new(name: :music, size: :sm)
        render_inline(component)
        expect(page).to have_css("svg.w-4.h-4")
      end

      it "applies medium size classes" do
        component = described_class.new(name: :music, size: :md)
        render_inline(component)
        expect(page).to have_css("svg.w-5.h-5")
      end

      it "applies large size classes" do
        component = described_class.new(name: :music, size: :lg)
        render_inline(component)
        expect(page).to have_css("svg.w-6.h-6")
      end
    end

    context "with custom color" do
      let(:params) { { name: :video, color: "text-red-500" } }

      it "applies custom color class" do
        render_inline(component)
        expect(page).to have_css("svg.text-red-500")
      end
    end

    context "with aria-label" do
      let(:params) { { name: :delete, aria_label: "Delete item" } }

      it "sets aria-label attribute" do
        render_inline(component)
        expect(page).to have_css('svg[aria-label="Delete item"]')
      end

      it "sets role attribute to img" do
        render_inline(component)
        expect(page).to have_css('svg[role="img"]')
      end
    end

    context "without aria-label" do
      let(:params) { { name: :spinner } }

      it "sets aria-hidden to true" do
        render_inline(component)
        expect(page).to have_css('svg[aria-hidden="true"]')
      end

      it "does not set role attribute" do
        render_inline(component)
        expect(page).not_to have_css('svg[role]')
      end
    end
  end

  describe "icon availability" do
    %i[image music video delete spinner play pause check].each do |icon_name|
      context "with #{icon_name} icon" do
        let(:params) { { name: icon_name } }

        it "renders without errors" do
          expect { render_inline(component) }.not_to raise_error
        end

        it "renders SVG path element" do
          render_inline(component)
          expect(page).to have_css("svg path")
        end
      end
    end
  end

  describe "error handling" do
    context "with invalid icon name" do
      let(:params) { { name: :nonexistent } }

      it "raises an error" do
        expect { render_inline(component) }.to raise_error(ArgumentError, /Unknown icon: nonexistent/)
      end
    end

    context "with invalid size" do
      let(:params) { { name: :image, size: :xxl } }

      it "raises an error" do
        expect { component }.to raise_error(ArgumentError, /Invalid size: xxl/)
      end
    end
  end

  describe "#css_classes" do
    it "combines size and color classes" do
      component = described_class.new(name: :music, size: :lg, color: "text-blue-600")
      expect(component.send(:css_classes)).to eq("w-6 h-6 text-blue-600")
    end

    it "returns only size classes when no color specified" do
      component = described_class.new(name: :play, size: :sm)
      expect(component.send(:css_classes)).to eq("w-4 h-4")
    end
  end

  describe "#icon_path" do
    let(:component) { described_class.new(name: :image) }

    it "returns the correct SVG path data" do
      path_data = component.send(:icon_path)
      expect(path_data).to be_a(String)
      expect(path_data).to include("m2.25 15.75")
    end
  end
end
