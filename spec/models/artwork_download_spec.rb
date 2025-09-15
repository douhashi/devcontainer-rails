require "rails_helper"

RSpec.describe Artwork, "#generate_download_filename", type: :model do
  let(:content) { create(:content, id: 1) }
  let(:artwork) { create(:artwork, content: content) }

  describe "#generate_download_filename" do
    context "with original variation" do
      it "generates correct filename for PNG" do
        allow(artwork.image).to receive(:original_filename).and_return("test.png")
        expect(artwork.generate_download_filename(:original)).to eq("content_0001_original.png")
      end

      it "generates correct filename for JPG" do
        allow(artwork.image).to receive(:original_filename).and_return("test.jpg")
        expect(artwork.generate_download_filename(:original)).to eq("content_0001_original.jpg")
      end

      it "generates correct filename for JPEG" do
        allow(artwork.image).to receive(:original_filename).and_return("test.jpeg")
        expect(artwork.generate_download_filename(:original)).to eq("content_0001_original.jpeg")
      end
    end

    context "with youtube_thumbnail variation" do
      it "generates correct filename" do
        expect(artwork.generate_download_filename(:youtube_thumbnail)).to eq("content_0001_youtube.jpg")
      end
    end

    context "with square variation" do
      it "generates correct filename" do
        expect(artwork.generate_download_filename(:square)).to eq("content_0001_square.jpg")
      end
    end

    context "with banner variation" do
      it "generates correct filename" do
        expect(artwork.generate_download_filename(:banner)).to eq("content_0001_banner.jpg")
      end
    end

    context "with different content IDs" do
      it "pads single digit IDs with zeros" do
        content.update!(id: 9)
        expect(artwork.generate_download_filename(:original)).to eq("content_0009_original.jpg")
      end

      it "pads double digit IDs with zeros" do
        content.update!(id: 99)
        expect(artwork.generate_download_filename(:original)).to eq("content_0099_original.jpg")
      end

      it "pads triple digit IDs with zeros" do
        content.update!(id: 999)
        expect(artwork.generate_download_filename(:original)).to eq("content_0999_original.jpg")
      end

      it "does not pad four digit IDs" do
        content.update!(id: 9999)
        expect(artwork.generate_download_filename(:original)).to eq("content_9999_original.jpg")
      end

      it "handles five digit IDs" do
        content.update!(id: 12345)
        expect(artwork.generate_download_filename(:original)).to eq("content_12345_original.jpg")
      end
    end
  end
end
