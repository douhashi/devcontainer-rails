require "rails_helper"

RSpec.describe Layout::MainContentComponent, type: :component do
  subject(:component) { described_class.new }

  describe "rendering" do
    before do
      render_inline(component) do
        "<h1>Page Title</h1><p>Content goes here</p>".html_safe
      end
    end

    it "renders the main content area" do
      expect(page).to have_css('.layout-main')
    end

    it "renders provided content" do
      expect(page).to have_content('Page Title')
      expect(page).to have_content('Content goes here')
    end

    it "has proper styling classes" do
      expect(page).to have_css('.layout-main')
    end
  end
end
