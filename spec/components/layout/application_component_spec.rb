require "rails_helper"

RSpec.describe Layout::ApplicationComponent, type: :component do
  subject(:component) { described_class.new(title: title) }

  let(:title) { "Test Application" }

  describe "#initialize" do
    it "sets the title" do
      expect(component.title).to eq(title)
    end

    context "when title is not provided" do
      subject(:component) { described_class.new }

      it "uses default title from Settings" do
        allow(Settings.app).to receive(:name).and_return("Default App")
        expect(component.title).to eq("Default App")
      end
    end
  end

  describe "rendering" do
    before do
      render_inline(component) do
        "<p>Main content</p>".html_safe
      end
    end

    it "renders the layout grid structure" do
      expect(page).to have_css('.layout-grid')
    end

    it "includes header component" do
      expect(page).to have_css('[data-testid="layout-header"]')
    end

    it "includes sidebar component" do
      expect(page).to have_css('[data-testid="layout-sidebar"]')
    end

    it "includes main content area" do
      expect(page).to have_css('.layout-main')
      expect(page).to have_content('Main content')
    end

    it "includes footer component" do
      expect(page).to have_css('[data-testid="layout-footer"]')
    end
  end
end
