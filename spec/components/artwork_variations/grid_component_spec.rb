require "rails_helper"

RSpec.describe ArtworkVariations::GridComponent, type: :component do
  let(:artwork) { create(:artwork) }
  let(:component) { described_class.new(artwork: artwork) }
  let(:rendered) { render_inline(component) }

  describe "rendering" do
    context "with original image only" do
      it "renders the original image" do
        expect(rendered).to have_css(".artwork-variations-grid")
        expect(rendered).to have_css(".variation-card", count: 1)
        expect(rendered).to have_text("オリジナル")
      end

      it "displays image with lazy loading" do
        expect(rendered).to have_css("img[loading='lazy']")
      end

      it "displays metadata" do
        expect(rendered).to have_css(".variation-metadata")
      end

      it "does not display file size" do
        expect(rendered).not_to have_text("ファイルサイズ")
      end
    end

    context "with YouTube thumbnail" do
      let(:artwork) do
        artwork = create(:artwork)
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
        allow(artwork).to receive(:youtube_thumbnail_url).and_return("/youtube_thumb.jpg")
        artwork
      end

      it "renders both original and YouTube thumbnail" do
        expect(rendered).to have_css(".variation-card", count: 2)
        expect(rendered).to have_text("オリジナル")
        expect(rendered).to have_text("YouTube用")
      end

      it "includes download button for YouTube thumbnail" do
        expect(rendered).to have_css(".download-button", count: 2)
      end
    end

    context "with future variations" do
      let(:artwork) do
        artwork = create(:artwork)
        allow(artwork).to receive(:all_variations).and_return([
          { type: :original, url: "/original.jpg", label: "オリジナル", metadata: { width: 1920, height: 1080, size: 2621440 } },
          { type: :youtube_thumbnail, url: "/youtube.jpg", label: "YouTube用", metadata: { width: 1280, height: 720, size: 1258291 } },
          { type: :square, url: "/square.jpg", label: "正方形", metadata: { width: 1080, height: 1080, size: 1887436 } }
        ])
        artwork
      end

      it "renders all variations" do
        expect(rendered).to have_css(".variation-card", count: 3)
        expect(rendered).to have_text("オリジナル")
        expect(rendered).to have_text("YouTube用")
        expect(rendered).to have_text("正方形")
      end
    end

    context "responsive design" do
      it "uses responsive grid classes" do
        expect(rendered).to have_css(".grid.grid-cols-1.sm\\:grid-cols-2.lg\\:grid-cols-3")
      end
    end

    context "accessibility" do
      it "includes alt attributes for images" do
        expect(rendered).to have_css("img[alt]")
      end
    end

    context "with no artwork" do
      let(:artwork) { nil }

      it "renders empty state" do
        expect(rendered).to have_css(".empty-state")
        expect(rendered).to have_text("アートワークがありません")
      end
    end
  end
end
