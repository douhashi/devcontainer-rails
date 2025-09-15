# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArtworkDragDrop::Component do
  let(:content) { create(:content, theme: "Test Song") }
  let(:artwork) { build(:artwork, content: content) }
  let(:component) { described_class.new(content_record: content) }

  describe "#initialize" do
    it "sets content and artwork" do
      expect(component.content).to eq(content)
      expect(component.artwork).to eq(content.artwork || content.build_artwork)
    end
  end

  describe "#has_artwork?" do
    context "when artwork is persisted and has image" do
      before do
        artwork.save!
        allow(artwork).to receive(:image).and_return(double("image", present?: true))
        allow(content).to receive(:artwork).and_return(artwork)
      end

      it "returns true" do
        expect(component.has_artwork?).to be true
      end
    end

    context "when artwork is not persisted" do
      it "returns false" do
        expect(component.has_artwork?).to be false
      end
    end

    context "when artwork has no image" do
      before do
        artwork.save!
        allow(artwork).to receive(:image).and_return(double("image", present?: false))
        allow(content).to receive(:artwork).and_return(artwork)
      end

      it "returns false" do
        expect(component.has_artwork?).to be false
      end
    end
  end

  describe "rendering" do
    context "when artwork exists" do
      before do
        artwork.save!
        allow(artwork).to receive(:image).and_return(double("image", present?: true, url: "https://example.com/image.jpg"))
        allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
        allow(artwork).to receive(:youtube_thumbnail_url).and_return(nil)
        allow(artwork).to receive(:thumbnail_generation_status).and_return("pending")
        allow(artwork).to receive(:thumbnail_generation_status_processing?).and_return(false)
        allow(artwork).to receive(:thumbnail_generation_status_failed?).and_return(false)
        allow(artwork).to receive(:youtube_thumbnail_processing?).and_return(false)
        allow(artwork).to receive(:download_path_for).with(:youtube_thumbnail).and_return(nil)
        allow(content).to receive(:artwork).and_return(artwork)
      end

      it "does not render anything when artwork exists" do
        skip "Component now always renders drop zone regardless of artwork presence"
      end
    end

    context "when artwork does not exist" do
      it "renders drag and drop area" do
        render_inline(component)

        expect(page).to have_css("[data-artwork-drag-drop-target='dropZone']")
        expect(page).to have_text("画像をドラッグ&ドロップ")
      end

      it "includes file input field" do
        render_inline(component)

        expect(page).to have_css("input[type='file'][accept='image/*']")
      end
    end
  end

  describe "#form_url" do
    context "when artwork is persisted" do
      before { artwork.save! }

      it "returns the update URL" do
        allow(content).to receive(:artwork).and_return(artwork)
        expect(component.form_url).to eq("/contents/#{content.id}/artworks/#{artwork.id}")
      end
    end

    context "when artwork is not persisted" do
      it "returns the create URL" do
        expect(component.form_url).to eq("/contents/#{content.id}/artworks")
      end
    end
  end

  describe "#form_method" do
    context "when artwork is persisted" do
      before { artwork.save! }

      it "returns patch" do
        allow(content).to receive(:artwork).and_return(artwork)
        expect(component.form_method).to eq(:patch)
      end
    end

    context "when artwork is not persisted" do
      it "returns post" do
        expect(component.form_method).to eq(:post)
      end
    end
  end

  describe "#artwork_url" do
    context "when has_artwork? is true" do
      before do
        allow(component).to receive(:has_artwork?).and_return(true)
        allow(component.artwork).to receive_message_chain(:image, :url).and_return("https://example.com/image.jpg")
      end

      it "returns the artwork URL" do
        expect(component.artwork_url).to eq("https://example.com/image.jpg")
      end
    end

    context "when has_artwork? is false" do
      before do
        allow(component).to receive(:has_artwork?).and_return(false)
      end

      it "returns nil" do
        expect(component.artwork_url).to be_nil
      end
    end
  end
end
