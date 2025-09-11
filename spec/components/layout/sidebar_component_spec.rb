require "rails_helper"

RSpec.describe Layout::SidebarComponent, type: :component do
  subject(:component) { described_class.new(navigation_items: navigation_items, current_path: current_path) }

  let(:navigation_items) do
    [
      { name: "Content", path: "/contents", icon: "document-text" },
      { name: "Tracks", path: "/tracks", icon: "musical-note" }
    ]
  end
  let(:current_path) { "/contents" }

  describe "#initialize" do
    it "sets navigation items" do
      expect(component.navigation_items).to eq(navigation_items)
    end

    it "sets current path" do
      expect(component.current_path).to eq(current_path)
    end
  end

  describe "#active_item?" do
    context "when current path is /contents" do
      let(:current_path) { "/contents" }

      it "returns true for exact match" do
        expect(component.active_item?("/contents")).to be true
      end

      it "returns false for other paths" do
        expect(component.active_item?("/tracks")).to be false
      end
    end

    context "when current path is a content subpage" do
      let(:current_path) { "/contents/123" }

      it "returns true for the parent content path" do
        expect(component.active_item?("/contents")).to be true
      end

      it "returns false for other paths" do
        expect(component.active_item?("/tracks")).to be false
      end
    end

    context "when current path is content new page" do
      let(:current_path) { "/contents/new" }

      it "returns true for the parent content path" do
        expect(component.active_item?("/contents")).to be true
      end
    end

    context "when current path is content edit page" do
      let(:current_path) { "/contents/123/edit" }

      it "returns true for the parent content path" do
        expect(component.active_item?("/contents")).to be true
      end
    end

    context "when current path has similar prefix but different" do
      let(:current_path) { "/content" }

      it "returns false for /contents path" do
        expect(component.active_item?("/contents")).to be false
      end
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
      expect(page).to have_css('a[href="/contents"][aria-current="page"]')
    end

    it "includes icons for navigation items" do
      expect(page).to have_css('[data-testid="nav-icon"]', count: 2)
    end

    it "does not include Artwork link" do
      expect(page).not_to have_link("Artwork")
    end

    it "has proper responsive behavior" do
      expect(page).to have_css('[data-testid="sidebar-overlay"]', visible: :all)
    end
  end
end
