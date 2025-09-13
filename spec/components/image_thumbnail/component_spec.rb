# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageThumbnail::Component do
  let(:image_url) { "https://example.com/image.jpg" }
  let(:label) { "オリジナル" }
  let(:image_type) { "original" }
  let(:selected) { false }

  subject(:component) do
    described_class.new(
      image_url: image_url,
      label: label,
      image_type: image_type,
      selected: selected
    )
  end

  describe "#initialize" do
    it "sets the provided attributes" do
      expect(component.image_url).to eq(image_url)
      expect(component.label).to eq(label)
      expect(component.image_type).to eq(image_type)
      expect(component.selected).to eq(selected)
    end
  end

  describe "rendering" do
    it "renders the thumbnail image with correct attributes" do
      render_inline(component)

      expect(page).to have_css("img[src='#{image_url}']")
      expect(page).to have_css("img[alt='#{label}']")
    end

    it "displays the label text" do
      render_inline(component)

      expect(page).to have_text(label)
    end

    it "has the correct data attributes for image switching" do
      render_inline(component)

      expect(page).to have_css("[data-image-type='#{image_type}']")
      expect(page).to have_css("[data-image-url='#{image_url}']")
    end

    context "when selected is true" do
      let(:selected) { true }

      it "applies the selected state styling" do
        render_inline(component)

        expect(page).to have_css(".ring-2.ring-blue-500")
      end
    end

    context "when selected is false" do
      it "does not apply the selected state styling" do
        render_inline(component)

        expect(page).not_to have_css(".ring-2.ring-blue-500")
      end
    end

    it "has clickable structure for image switching" do
      render_inline(component)

      expect(page).to have_css("[role='button']")
      expect(page).to have_css("[tabindex='0']")
    end
  end

  describe "#thumbnail_container_class" do
    context "when selected" do
      let(:selected) { true }

      it "includes selected styling" do
        expected_class = "relative cursor-pointer rounded-lg overflow-hidden ring-2 ring-blue-500 bg-blue-50"
        expect(component.thumbnail_container_class).to eq(expected_class)
      end
    end

    context "when not selected" do
      it "includes default styling" do
        expected_class = "relative cursor-pointer rounded-lg overflow-hidden hover:ring-2 hover:ring-blue-300 transition-all"
        expect(component.thumbnail_container_class).to eq(expected_class)
      end
    end
  end
end
