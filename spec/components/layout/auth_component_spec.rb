require "rails_helper"

RSpec.describe Layout::AuthComponent, type: :component do
  describe "#initialize" do
    it "sets the title" do
      component = described_class.new(title: "Custom Title")
      expect(component.send(:title)).to eq("Custom Title")
    end

    context "when title is not provided" do
      it "uses default title from Settings" do
        component = described_class.new
        expect(component.send(:title)).to eq(Settings.app.name)
      end
    end
  end

  describe "rendering" do
    it "renders the auth layout container" do
      render_inline(described_class.new) { "Content" }
      expect(page).to have_css(".min-h-screen.bg-gray-950")
    end

    it "includes the auth header component" do
      render_inline(described_class.new) { "Content" }
      expect(page).to have_css("header.auth-header")
    end

    it "does not include sidebar" do
      render_inline(described_class.new) { "Content" }
      expect(page).not_to have_css(".layout-sidebar")
    end

    it "renders content in centered container" do
      render_inline(described_class.new) { "Test Content" }
      expect(page).to have_css(".auth-content")
      expect(page).to have_text("Test Content")
    end

    it "has proper flexbox layout for centering" do
      render_inline(described_class.new) { "Content" }
      expect(page).to have_css("main.flex-1.flex.items-center.justify-center")
    end

    it "applies dark theme classes" do
      render_inline(described_class.new) { "Content" }
      expect(page).to have_css(".bg-gray-950.text-gray-100")
    end
  end
end
