# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArtworkGallery::Component do
  let(:content) { create(:content, theme: "Test Song") }
  let(:artwork) { create(:artwork, content: content) }

  subject(:component) { described_class.new(artwork: artwork) }

  describe "#initialize" do
    it "sets the artwork" do
      expect(component.artwork).to eq(artwork)
    end
  end

  describe "#should_render?" do
    context "when artwork has image" do
      it "returns true" do
        allow(artwork).to receive(:image).and_return(double("image", present?: true))
        expect(component.should_render?).to be true
      end
    end

    context "when artwork has no image" do
      it "returns false" do
        allow(artwork).to receive(:image).and_return(double("image", present?: false))
        expect(component.should_render?).to be false
      end
    end
  end

  describe "#thumbnail_images" do
    before do
      allow(artwork).to receive(:image).and_return(double("image", present?: true, url: "https://example.com/original.jpg"))
    end

    context "when artwork has original image only" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
      end

      it "returns only the original image" do
        images = component.thumbnail_images
        expect(images.size).to eq(1)
        expect(images.first[:image_type]).to eq("original")
        expect(images.first[:label]).to eq("オリジナル")
      end
    end

    context "when artwork has both original and YouTube thumbnail" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
        allow(artwork).to receive(:youtube_thumbnail_url).and_return("https://example.com/youtube.jpg")
      end

      it "returns both images" do
        images = component.thumbnail_images
        expect(images.size).to eq(2)

        original_image = images.find { |img| img[:image_type] == "original" }
        youtube_image = images.find { |img| img[:image_type] == "youtube" }

        expect(original_image[:label]).to eq("オリジナル")
        expect(original_image[:image_url]).to eq("https://example.com/original.jpg")

        expect(youtube_image[:label]).to eq("YouTube")
        expect(youtube_image[:image_url]).to eq("https://example.com/youtube.jpg")
      end
    end
  end

  describe "rendering" do
    before do
      allow(artwork).to receive(:image).and_return(double("image", present?: true, url: "https://example.com/original.jpg"))
    end

    context "when should_render? is false" do
      before do
        allow(component).to receive(:should_render?).and_return(false)
      end

      it "renders nothing" do
        render_inline(component)
        expect(page).not_to have_css(".artwork-gallery")
      end
    end

    context "when should_render? is true" do
      before do
        allow(component).to receive(:should_render?).and_return(true)
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
        allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
      end

      it "renders the gallery container" do
        render_inline(component)
        expect(page).to have_css(".artwork-gallery")
      end

      it "renders thumbnail images" do
        render_inline(component)
        expect(page).to have_css("[data-image-type='original']")
      end

      context "with YouTube thumbnail" do
        before do
          allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
          allow(artwork).to receive(:youtube_thumbnail_url).and_return("https://example.com/youtube.jpg")
        end

        it "renders both original and YouTube thumbnails" do
          render_inline(component)
          expect(page).to have_css("[data-image-type='original']")
          expect(page).to have_css("[data-image-type='youtube']")
        end
      end
    end
  end

  describe "#gallery_container_class" do
    it "returns the correct CSS classes" do
      expected_class = "artwork-gallery mt-4 flex gap-3 justify-center"
      expect(component.gallery_container_class).to eq(expected_class)
    end
  end
end
