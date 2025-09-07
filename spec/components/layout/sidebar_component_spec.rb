require "rails_helper"

RSpec.describe Layout::SidebarComponent, type: :component do
  subject(:component) { described_class.new(navigation_items: navigation_items, current_path: current_path) }

  let(:navigation_items) do
    [
      { name: "Content", path: "/content", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" },
      { name: "Artwork", path: "/artwork", icon: "photo" }
    ]
  end
  let(:current_path) { "/content" }

  describe "#initialize" do
    it "sets navigation items" do
      expect(component.navigation_items).to eq(navigation_items)
    end

    it "sets current path" do
      expect(component.current_path).to eq(current_path)
    end
  end

  describe "#active_item?" do
    it "returns true for the current path" do
      expect(component.active_item?("/content")).to be true
    end

    it "returns false for other paths" do
      expect(component.active_item?("/tracks")).to be false
    end
  end

  describe "rendering" do
    before do
      render_inline(component)
    end

    it "renders the sidebar with correct styling" do
      expect(page).to have_css('.layout-sidebar')
    end

    it "renders all navigation items" do
      navigation_items.each do |item|
        expect(page).to have_link(item[:name], href: item[:path])
      end
    end

    it "marks the current item as active" do
      expect(page).to have_css('a[href="/content"][aria-current="page"]')
    end

    it "includes icons for navigation items" do
      expect(page).to have_css('[data-testid="nav-icon"]', count: 3)
    end

    it "has proper responsive behavior" do
      expect(page).to have_css('[data-testid="sidebar-overlay"]', visible: :all)
    end
  end
end
