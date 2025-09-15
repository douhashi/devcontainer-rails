# frozen_string_literal: true

require "rails_helper"

RSpec.describe Layout::HeaderComponent, type: :component do
  let(:component) { described_class.new(**options) }
  let(:title) { "Test App" }
  let(:options) { { title: title } }

  describe "rendering" do
    it "renders the default static user info" do
      render_inline(component)

      expect(page).to have_content("Admin User")
      expect(page).to have_content("A")
      expect(page).to_not have_css("[data-testid='user-dropdown']")
    end

    it "renders the title" do
      render_inline(component)

      expect(page).to have_link(title, href: "/")
    end
  end

  describe "with show_menu_toggle option" do
    context "when show_menu_toggle is true" do
      let(:options) { { title: title, show_menu_toggle: true } }

      it "renders the menu toggle button" do
        render_inline(component)

        expect(page).to have_css("button[data-action='click->layout#toggleSidebar']")
      end
    end

    context "when show_menu_toggle is false" do
      let(:options) { { title: title, show_menu_toggle: false } }

      it "does not render the menu toggle button" do
        render_inline(component)

        expect(page).to_not have_css("button[data-action='click->layout#toggleSidebar']")
      end
    end
  end
end
