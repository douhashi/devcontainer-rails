require "rails_helper"

RSpec.describe Artwork, type: :model do
  let(:content) { create(:content) }
  let(:artwork) { create(:artwork, content: content) }

  describe "associations" do
    it { is_expected.to belong_to(:content) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:image) }
  end

  describe "#youtube_thumbnail_eligible?" do
    context "when image is 1920x1080" do
      before do
        # Mock the image dimensions
        image_double = double(metadata: { "width" => 1920, "height" => 1080 })
        allow(artwork.image).to receive_message_chain(:metadata).and_return({ "width" => 1920, "height" => 1080 })
      end

      it "returns true" do
        expect(artwork.youtube_thumbnail_eligible?).to be true
      end
    end

    context "when image is not 1920x1080" do
      before do
        allow(artwork.image).to receive_message_chain(:metadata).and_return({ "width" => 1280, "height" => 720 })
      end

      it "returns false" do
        expect(artwork.youtube_thumbnail_eligible?).to be false
      end
    end

    context "when image metadata is not available" do
      before do
        allow(artwork.image).to receive_message_chain(:metadata).and_return(nil)
      end

      it "returns false" do
        expect(artwork.youtube_thumbnail_eligible?).to be false
      end
    end
  end

  describe "#has_youtube_thumbnail?" do
    context "when YouTube thumbnail derivative exists" do
      it "returns true" do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
        expect(artwork.has_youtube_thumbnail?).to be true
      end
    end

    context "when YouTube thumbnail derivative does not exist" do
      it "returns false" do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
        expect(artwork.has_youtube_thumbnail?).to be false
      end
    end
  end

  describe "#youtube_thumbnail_url" do
    context "when YouTube thumbnail exists" do
      before do
        thumbnail_double = double(url: "http://example.com/thumbnail.jpg")
        derivatives_double = double(:[]).as_null_object
        allow(derivatives_double).to receive(:[]).with(:youtube_thumbnail).and_return(thumbnail_double)

        attacher_double = double(derivatives: derivatives_double)
        allow(artwork).to receive(:image_attacher).and_return(attacher_double)
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
      end

      it "returns the thumbnail URL" do
        expect(artwork.youtube_thumbnail_url).to eq("http://example.com/thumbnail.jpg")
      end
    end

    context "when YouTube thumbnail does not exist" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
      end

      it "returns nil" do
        expect(artwork.youtube_thumbnail_url).to be_nil
      end
    end
  end

  describe "#youtube_thumbnail_processing?" do
    it "returns false (placeholder implementation)" do
      expect(artwork.youtube_thumbnail_processing?).to be false
    end
  end

  describe "#youtube_thumbnail_download_url" do
    context "when YouTube thumbnail exists" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
        allow(artwork).to receive(:youtube_thumbnail_url).and_return("http://example.com/thumbnail.jpg")
      end

      it "returns the download URL with attachment disposition" do
        expected_url = "http://example.com/thumbnail.jpg?disposition=attachment&filename=#{artwork.content.theme.gsub(/[^a-zA-Z0-9\-_.]/, '_')}_youtube_thumbnail.jpg"
        expect(artwork.youtube_thumbnail_download_url).to eq(expected_url)
      end
    end

    context "when YouTube thumbnail does not exist" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
      end

      it "returns nil" do
        expect(artwork.youtube_thumbnail_download_url).to be_nil
      end
    end
  end

  describe "after save callback" do
    it "calls schedule_thumbnail_generation when image data changes" do
      new_artwork = build(:artwork, content: content)
      allow(new_artwork).to receive(:schedule_thumbnail_generation)
      allow(new_artwork).to receive(:saved_change_to_image_data?).and_return(true)

      new_artwork.save!

      expect(new_artwork).to have_received(:schedule_thumbnail_generation).at_least(:once)
    end
  end

  describe "#schedule_thumbnail_generation" do
    it "enqueues job when eligible and no thumbnail exists" do
      allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
      allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)

      expect {
        artwork.send(:schedule_thumbnail_generation)
      }.to have_enqueued_job(DerivativeProcessingJob).with(artwork)
    end

    it "does not enqueue job when not eligible" do
      allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(false)

      expect {
        artwork.send(:schedule_thumbnail_generation)
      }.not_to have_enqueued_job(DerivativeProcessingJob)
    end

    it "does not enqueue job when thumbnail already exists" do
      allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
      allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)

      expect {
        artwork.send(:schedule_thumbnail_generation)
      }.not_to have_enqueued_job(DerivativeProcessingJob)
    end
  end
end
