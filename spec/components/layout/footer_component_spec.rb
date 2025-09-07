require "rails_helper"

RSpec.describe Layout::FooterComponent, type: :component do
  subject(:component) { described_class.new }

  describe "rendering" do
    before do
      render_inline(component)
    end

    it "renders the footer with correct styling" do
      expect(page).to have_css('.layout-footer')
    end

    it "includes version information" do
      expect(page).to have_css('[data-testid="app-version"]')
    end

    it "includes copyright information" do
      expect(page).to have_content('©')
    end

    it "has proper background styling" do
      expect(page).to have_css('.layout-footer')
    end
  end
end
