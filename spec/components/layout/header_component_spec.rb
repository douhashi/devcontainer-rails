require "rails_helper"

RSpec.describe Layout::HeaderComponent, type: :component do
  subject(:component) { described_class.new(title: title, show_menu_toggle: show_menu_toggle) }

  let(:title) { "Test App" }
  let(:show_menu_toggle) { true }

  describe "#initialize" do
    it "sets the title" do
      expect(component.title).to eq(title)
    end

    it "sets show_menu_toggle" do
      expect(component.show_menu_toggle).to eq(show_menu_toggle)
    end
  end

  describe "rendering" do
    before do
      render_inline(component)
    end

    it "renders the header with correct styling" do
      expect(page).to have_css('.layout-header')
    end

    it "displays the application title" do
      expect(page).to have_content(title)
    end

    context "when show_menu_toggle is true" do
      it "shows the menu toggle button" do
        expect(page).to have_css('[data-action*="layout#toggleSidebar"]')
      end
    end

    context "when show_menu_toggle is false" do
      let(:show_menu_toggle) { false }

      it "does not show the menu toggle button" do
        expect(page).not_to have_css('[data-action*="layout#toggleSidebar"]')
      end
    end

    it "includes user info area" do
      expect(page).to have_css('[data-testid="user-info"]')
    end
  end
end
