require "rails_helper"

RSpec.describe Layout::AuthHeaderComponent, type: :component do
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
    it "renders the header with auth-specific styling" do
      render_inline(described_class.new)
      expect(page).to have_css("header.auth-header")
    end

    it "displays the application title" do
      render_inline(described_class.new(title: "Test App"))
      expect(page).to have_text("Test App")
    end

    it "renders title as home link" do
      render_inline(described_class.new)
      expect(page).to have_link(Settings.app.name, href: "/")
    end

    it "does not show the menu toggle button" do
      render_inline(described_class.new)
      expect(page).not_to have_css("[data-controller='menu-toggle']")
    end

    it "does not include user info area" do
      render_inline(described_class.new)
      expect(page).not_to have_css(".user-info")
    end

    it "has centered layout styling" do
      render_inline(described_class.new)
      expect(page).to have_css(".flex.justify-center.items-center")
    end
  end
end
