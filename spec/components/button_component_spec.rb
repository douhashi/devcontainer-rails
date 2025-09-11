# frozen_string_literal: true

require "rails_helper"

RSpec.describe Button::Component, type: :component do
  describe "#initialize" do
    it "accepts required text parameter" do
      component = described_class.new(text: "Click me")
      expect(component).to be_a(described_class)
    end

    it "accepts optional variant parameter" do
      component = described_class.new(text: "Click me", variant: :secondary)
      expect(component).to be_a(described_class)
    end

    it "accepts optional size parameter" do
      component = described_class.new(text: "Click me", size: :lg)
      expect(component).to be_a(described_class)
    end

    it "accepts optional loading parameter" do
      component = described_class.new(text: "Click me", loading: true)
      expect(component).to be_a(described_class)
    end

    it "accepts optional disabled parameter" do
      component = described_class.new(text: "Click me", disabled: true)
      expect(component).to be_a(described_class)
    end

    it "accepts additional options" do
      component = described_class.new(
        text: "Click me",
        data: { controller: "test" },
        class: "custom-class"
      )
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    context "with default parameters" do
      it "renders a primary button with medium size" do
        rendered = render_inline(described_class.new(text: "Click me"))

        expect(rendered).to have_css("button", text: "Click me")
        expect(rendered).to have_css("button.bg-blue-600")
        expect(rendered).to have_css("button.text-white")
        expect(rendered).to have_css("button.px-4")
        expect(rendered).to have_css("button.py-2")
      end
    end

    context "with variant :primary" do
      it "renders primary button styles" do
        rendered = render_inline(described_class.new(text: "Primary", variant: :primary))

        expect(rendered).to have_css("button.bg-blue-600")
        expect(rendered).to have_css("button.hover\\:bg-blue-700")
        expect(rendered).to have_css("button.text-white")
      end
    end

    context "with variant :secondary" do
      it "renders secondary button styles" do
        rendered = render_inline(described_class.new(text: "Secondary", variant: :secondary))

        expect(rendered).to have_css("button.bg-gray-200")
        expect(rendered).to have_css("button.hover\\:bg-gray-300")
        expect(rendered).to have_css("button.text-gray-800")
      end
    end

    context "with variant :secondary_dark" do
      it "renders secondary_dark button styles" do
        rendered = render_inline(described_class.new(text: "Secondary Dark", variant: :secondary_dark))

        expect(rendered).to have_css("button.bg-gray-700")
        expect(rendered).to have_css("button.hover\\:bg-gray-600")
        expect(rendered).to have_css("button.text-gray-200")
      end
    end

    context "with variant :danger" do
      it "renders danger button styles" do
        rendered = render_inline(described_class.new(text: "Delete", variant: :danger))

        expect(rendered).to have_css("button.bg-red-600")
        expect(rendered).to have_css("button.hover\\:bg-red-700")
        expect(rendered).to have_css("button.text-white")
      end
    end

    context "with variant :ghost" do
      it "renders ghost button styles" do
        rendered = render_inline(described_class.new(text: "Ghost", variant: :ghost))

        expect(rendered).to have_css("button.bg-transparent")
        expect(rendered).to have_css("button.hover\\:bg-gray-100")
        expect(rendered).to have_css("button.text-gray-700")
        expect(rendered).to have_css("button.border")
        expect(rendered).to have_css("button.border-gray-300")
      end
    end

    context "with size :sm" do
      it "renders small button size" do
        rendered = render_inline(described_class.new(text: "Small", size: :sm))

        expect(rendered).to have_css("button.px-3")
        expect(rendered).to have_css("button.py-1\\.5")
        expect(rendered).to have_css("button.text-sm")
      end
    end

    context "with size :md" do
      it "renders medium button size" do
        rendered = render_inline(described_class.new(text: "Medium", size: :md))

        expect(rendered).to have_css("button.px-4")
        expect(rendered).to have_css("button.py-2")
        expect(rendered).to have_css("button.text-base")
      end
    end

    context "with size :lg" do
      it "renders large button size" do
        rendered = render_inline(described_class.new(text: "Large", size: :lg))

        expect(rendered).to have_css("button.px-6")
        expect(rendered).to have_css("button.py-3")
        expect(rendered).to have_css("button.text-lg")
      end
    end

    context "with loading state" do
      it "shows spinner icon and disables button" do
        rendered = render_inline(described_class.new(text: "Loading", loading: true))

        expect(rendered).to have_css("button[disabled]")
        expect(rendered).to have_css("button[aria-busy='true']")
        expect(rendered).to have_css("svg.animate-spin")
        expect(rendered).to have_css("button", text: "Loading")
      end

      it "applies opacity to loading button" do
        rendered = render_inline(described_class.new(text: "Loading", loading: true))

        expect(rendered).to have_css("button.opacity-75")
        expect(rendered).to have_css("button.cursor-not-allowed")
      end
    end

    context "with disabled state" do
      it "disables the button" do
        rendered = render_inline(described_class.new(text: "Disabled", disabled: true))

        expect(rendered).to have_css("button[disabled]")
        expect(rendered).to have_css("button[aria-disabled='true']")
      end

      it "applies disabled styles" do
        rendered = render_inline(described_class.new(text: "Disabled", disabled: true))

        expect(rendered).to have_css("button.opacity-50")
        expect(rendered).to have_css("button.cursor-not-allowed")
      end
    end

    context "with additional CSS classes" do
      it "merges custom classes with default ones" do
        rendered = render_inline(described_class.new(
          text: "Custom",
          class: "custom-class another-class"
        ))

        expect(rendered).to have_css("button.custom-class")
        expect(rendered).to have_css("button.another-class")
        expect(rendered).to have_css("button.bg-blue-600") # Still has default classes
      end
    end

    context "with data attributes" do
      it "passes through data attributes" do
        rendered = render_inline(described_class.new(
          text: "Data Test",
          data: {
            controller: "test-controller",
            action: "click->test-controller#click",
            test_value: "123"
          }
        ))

        expect(rendered).to have_css("button[data-controller='test-controller']")
        expect(rendered).to have_css("button[data-action='click->test-controller#click']")
        expect(rendered).to have_css("button[data-test-value='123']")
      end
    end

    context "with block content" do
      it "renders block content instead of text parameter" do
        rendered = render_inline(described_class.new(text: "Ignored")) do
          "<span>Custom Content</span>".html_safe
        end

        expect(rendered).to have_css("button span", text: "Custom Content")
        expect(rendered).not_to have_text("Ignored")
      end
    end

    context "with type attribute" do
      it "accepts button type" do
        rendered = render_inline(described_class.new(text: "Submit", type: "submit"))

        expect(rendered).to have_css("button[type='submit']")
      end

      it "defaults to button type" do
        rendered = render_inline(described_class.new(text: "Button"))

        expect(rendered).to have_css("button[type='button']")
      end
    end

    context "with href for link buttons" do
      it "renders as link when href is provided" do
        rendered = render_inline(described_class.new(text: "Link", href: "/path"))

        expect(rendered).to have_css("a[href='/path']", text: "Link")
        expect(rendered).not_to have_css("button")
      end

      it "applies button styles to link" do
        rendered = render_inline(described_class.new(text: "Link", href: "/path", variant: :primary))

        expect(rendered).to have_css("a.bg-blue-600")
        expect(rendered).to have_css("a.inline-flex")
      end
    end

    context "accessibility" do
      it "includes proper ARIA attributes for loading state" do
        rendered = render_inline(described_class.new(text: "Loading", loading: true))

        expect(rendered).to have_css("button[aria-busy='true']")
      end

      it "includes proper ARIA attributes for disabled state" do
        rendered = render_inline(described_class.new(text: "Disabled", disabled: true))

        expect(rendered).to have_css("button[aria-disabled='true']")
      end
    end

    context "complex combinations" do
      it "handles loading + disabled correctly" do
        rendered = render_inline(described_class.new(
          text: "Processing",
          loading: true,
          disabled: true
        ))

        expect(rendered).to have_css("button[disabled]")
        expect(rendered).to have_css("button[aria-busy='true']")
        expect(rendered).to have_css("button[aria-disabled='true']")
        expect(rendered).to have_css("svg.animate-spin")
      end

      it "handles variant + size + custom classes" do
        rendered = render_inline(described_class.new(
          text: "Complex",
          variant: :secondary,
          size: :lg,
          class: "custom-margin"
        ))

        expect(rendered).to have_css("button.bg-gray-200")
        expect(rendered).to have_css("button.px-6")
        expect(rendered).to have_css("button.py-3")
        expect(rendered).to have_css("button.custom-margin")
      end
    end
  end
end
