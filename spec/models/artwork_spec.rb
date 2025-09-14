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
      let(:artwork) { create(:artwork, :with_fhd_image, content: content) }

      it "returns true" do
        expect(artwork.youtube_thumbnail_eligible?).to be true
      end
    end

    context "when image is not 1920x1080" do
      let(:artwork) { create(:artwork, :with_hd_image, content: content) }

      it "returns false" do
        expect(artwork.youtube_thumbnail_eligible?).to be false
      end
    end

    context "when image metadata is not available" do
      let(:artwork) { create(:artwork, content: content) }

      before do
        # 作成後にメタデータをnilに設定
        allow(artwork.image).to receive(:metadata).and_return(nil)
      end

      it "returns false" do
        expect(artwork.youtube_thumbnail_eligible?).to be false
      end
    end
  end

  describe "#has_youtube_thumbnail?" do
    context "when YouTube thumbnail derivative exists" do
      let(:artwork) { create(:artwork, :with_youtube_thumbnail, content: content) }

      it "returns true" do
        expect(artwork.has_youtube_thumbnail?).to be true
      end
    end

    context "when YouTube thumbnail derivative does not exist" do
      it "returns false" do
        expect(artwork.has_youtube_thumbnail?).to be false
      end
    end
  end

  describe "#youtube_thumbnail_url" do
    context "when YouTube thumbnail exists" do
      let(:artwork) { create(:artwork, :with_youtube_thumbnail, content: content) }

      it "returns the thumbnail URL" do
        expect(artwork.youtube_thumbnail_url).to be_present
        expect(artwork.youtube_thumbnail_url).to be_a(String)
      end
    end

    context "when YouTube thumbnail does not exist" do
      it "returns nil" do
        expect(artwork.youtube_thumbnail_url).to be_nil
      end
    end
  end

  describe "#youtube_thumbnail_processing?" do
    context "when status is processing" do
      before do
        artwork.thumbnail_generation_status_processing!
      end

      it "returns true" do
        expect(artwork.youtube_thumbnail_processing?).to be true
      end
    end

    context "when status is not processing" do
      before do
        artwork.thumbnail_generation_status_completed!
      end

      it "returns false" do
        expect(artwork.youtube_thumbnail_processing?).to be false
      end
    end
  end

  describe "thumbnail_generation_status" do
    it "has default status of pending" do
      new_artwork = Artwork.new
      expect(new_artwork.thumbnail_generation_status_pending?).to be true
    end

    it "can transition to processing" do
      artwork.thumbnail_generation_status_processing!
      expect(artwork.thumbnail_generation_status_processing?).to be true
    end

    it "can transition to completed" do
      artwork.thumbnail_generation_status_completed!
      expect(artwork.thumbnail_generation_status_completed?).to be true
    end

    it "can transition to failed" do
      artwork.thumbnail_generation_status_failed!
      expect(artwork.thumbnail_generation_status_failed?).to be true
    end
  end

  describe "#mark_thumbnail_generation_started!" do
    it "updates status to processing and clears error" do
      artwork.update!(thumbnail_generation_error: "Previous error")
      artwork.mark_thumbnail_generation_started!

      expect(artwork.thumbnail_generation_status_processing?).to be true
      expect(artwork.thumbnail_generation_error).to be_nil
    end
  end

  describe "#mark_thumbnail_generation_completed!" do
    it "updates status to completed and sets timestamp" do
      artwork.mark_thumbnail_generation_completed!

      expect(artwork.thumbnail_generation_status_completed?).to be true
      expect(artwork.thumbnail_generated_at).to be_present
      expect(artwork.thumbnail_generation_error).to be_nil
    end
  end

  describe "#mark_thumbnail_generation_failed!" do
    it "updates status to failed and stores error message" do
      error_message = "Failed to generate thumbnail"
      artwork.mark_thumbnail_generation_failed!(error_message)

      expect(artwork.thumbnail_generation_status_failed?).to be true
      expect(artwork.thumbnail_generation_error).to eq(error_message)
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

  # Callback tests are disabled since thumbnail generation is now synchronous
  # describe "after save callback" do
  #   it "calls schedule_thumbnail_generation when image data changes" do
  #     new_artwork = build(:artwork, content: content)
  #     allow(new_artwork).to receive(:schedule_thumbnail_generation)
  #     allow(new_artwork).to receive(:saved_change_to_image_data?).and_return(true)

  #     new_artwork.save!

  #     expect(new_artwork).to have_received(:schedule_thumbnail_generation).at_least(:once)
  #   end
  # end

  # describe "#schedule_thumbnail_generation" do
  #   it "enqueues job when eligible and no thumbnail exists" do
  #     allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
  #     allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)

  #     expect {
  #       artwork.send(:schedule_thumbnail_generation)
  #     }.to have_enqueued_job(DerivativeProcessingJob).with(artwork)
  #   end

  #   it "does not enqueue job when not eligible" do
  #     allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(false)

  #     expect {
  #       artwork.send(:schedule_thumbnail_generation)
  #     }.not_to have_enqueued_job(DerivativeProcessingJob)
  #   end

  #   it "does not enqueue job when thumbnail already exists" do
  #     allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
  #     allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)

  #     expect {
  #       artwork.send(:schedule_thumbnail_generation)
  #     }.not_to have_enqueued_job(DerivativeProcessingJob)
  #   end
  # end
end
