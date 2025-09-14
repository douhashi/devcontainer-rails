require "rails_helper"
require "fileutils"

RSpec.describe DerivativeProcessingJob, type: :job do
  let(:content) { create(:content) }
  let(:image_file) { fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg') }
  let(:artwork) { create(:artwork, content: content, image: image_file) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe "#perform" do
    context "when artwork is eligible for thumbnail generation" do
      it "updates status during thumbnail generation" do
        # Skip callbacks to prevent double job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)

        # Create artwork directly without triggering callbacks
        test_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))

        # Re-enable callbacks
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Only mock the external service (ThumbnailGenerationService)
        service = instance_double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service)

        # Mock the generate method to actually create a test thumbnail file
        allow(service).to receive(:generate) do |args|
          # Copy the HD placeholder as the generated thumbnail
          FileUtils.cp('spec/fixtures/files/images/hd_placeholder.jpg', args[:output_path])
          {
            input_size: { width: 1920, height: 1080 },
            output_size: { width: 1280, height: 720 },
            file_size: File.size(args[:output_path])
          }
        end

        # Expect status updates
        expect(test_artwork).to receive(:mark_thumbnail_generation_started!)
        expect(test_artwork).to receive(:mark_thumbnail_generation_completed!)

        # Run the job
        described_class.perform_now(test_artwork)

        # Verify the artwork has the thumbnail
        test_artwork.reload
        expect(test_artwork.has_youtube_thumbnail?).to be true
      end

      it "generates YouTube thumbnail successfully" do
        # Skip callbacks to prevent double job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)

        # Create artwork directly without triggering callbacks
        test_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))

        # Re-enable callbacks
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Only mock the external service (ThumbnailGenerationService)
        service = instance_double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service)

        # Mock the generate method to actually create a test thumbnail file
        allow(service).to receive(:generate) do |args|
          # Copy the HD placeholder as the generated thumbnail
          FileUtils.cp('spec/fixtures/files/images/hd_placeholder.jpg', args[:output_path])
          {
            input_size: { width: 1920, height: 1080 },
            output_size: { width: 1280, height: 720 },
            file_size: File.size(args[:output_path])
          }
        end

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{test_artwork.id}")
        expect(Rails.logger).to receive(:info).with(/Successfully generated YouTube thumbnail/)

        # Run the job
        described_class.perform_now(test_artwork)

        # Verify the artwork has the thumbnail
        test_artwork.reload
        expect(test_artwork.has_youtube_thumbnail?).to be true
      end

      it "skips if artwork already has thumbnail" do
        # Set up the artwork to have a thumbnail
        attacher = artwork.image_attacher
        # Upload the HD placeholder as the existing thumbnail
        File.open('spec/fixtures/files/images/hd_placeholder.jpg') do |file|
          thumbnail = attacher.upload(file, :store)
          attacher.set_derivatives(youtube_thumbnail: thumbnail)
        end
        artwork.save!

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{artwork.id}")
        expect(Rails.logger).to receive(:info).with("Artwork #{artwork.id} already has YouTube thumbnail, skipping")
        expect(ThumbnailGenerationService).not_to receive(:new)

        described_class.perform_now(artwork)
      end

      it "skips if artwork is not eligible" do
        # Create artwork with non-eligible dimensions
        non_eligible_image = fixture_file_upload('images/hd_placeholder.jpg', 'image/jpeg')
        non_eligible_artwork = create(:artwork, content: content, image: non_eligible_image)

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{non_eligible_artwork.id}")
        expect(Rails.logger).to receive(:info).with("Artwork #{non_eligible_artwork.id} is not eligible for YouTube thumbnail generation")
        expect(ThumbnailGenerationService).not_to receive(:new)

        described_class.perform_now(non_eligible_artwork)
      end
    end

    context "when artwork record is invalid" do
      it "returns early if artwork is not persisted" do
        # Create an unpersisted artwork
        unpersisted_artwork = build(:artwork, content: content)

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{unpersisted_artwork.id}")
        expect(Rails.logger).to receive(:warn).with("Artwork record not found or has been deleted: #{unpersisted_artwork.id}")
        expect(ThumbnailGenerationService).not_to receive(:new)

        described_class.perform_now(unpersisted_artwork)
      end

      it "returns early if artwork has no image" do
        # Create artwork and then remove image
        artwork_without_image = create(:artwork, content: content)
        artwork_without_image.image = nil
        artwork_without_image.save(validate: false)

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{artwork_without_image.id}")
        expect(Rails.logger).to receive(:warn).with("Artwork record not found or has been deleted: #{artwork_without_image.id}")
        expect(ThumbnailGenerationService).not_to receive(:new)

        described_class.perform_now(artwork_without_image)
      end
    end

    context "when image download fails" do
      it "logs error when download fails" do
        # Create a fresh artwork to ensure it's eligible
        # Use skip_callback to prevent automatic job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)
        fresh_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Clear any enqueued jobs
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear

        # Ensure the artwork is eligible and doesn't have thumbnail yet
        expect(fresh_artwork.youtube_thumbnail_eligible?).to be true
        expect(fresh_artwork.has_youtube_thumbnail?).to be false

        # Check if fresh_artwork is correctly persisted
        expect(fresh_artwork.persisted?).to be true
        expect(fresh_artwork.image.present?).to be true

        # Only mock the download method to simulate failure
        # We need to ensure this happens after the eligibility checks
        allow_any_instance_of(Shrine::UploadedFile).to receive(:download).and_raise(StandardError, "Download failed")

        # Allow some logs to pass through for debugging
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:debug)
        expect(Rails.logger).to receive(:error).with("Failed to download image for artwork #{fresh_artwork.id}: Download failed")

        # Use perform_now which doesn't trigger retries in test environment
        # The job should handle the error and log it
        expect {
          described_class.new.perform(fresh_artwork)
        }.to raise_error(StandardError, "Download failed")
      end
    end

    context "when thumbnail generation fails" do
      it "updates status to failed when error occurs" do
        # Create a fresh artwork to ensure it's eligible
        # Use skip_callback to prevent automatic job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)
        fresh_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Clear any enqueued jobs
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear

        # Ensure the artwork is eligible and doesn't have thumbnail yet
        expect(fresh_artwork.youtube_thumbnail_eligible?).to be true
        expect(fresh_artwork.has_youtube_thumbnail?).to be false

        # Only mock the service to simulate failure
        service = instance_double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service)
        allow(service).to receive(:generate).and_raise(ThumbnailGenerationService::GenerationError, "Generation failed")

        # Expect status updates
        expect(fresh_artwork).to receive(:mark_thumbnail_generation_started!)
        expect(fresh_artwork).to receive(:mark_thumbnail_generation_failed!).with("Generation failed")

        # Use perform method directly which doesn't trigger retries in test environment
        expect {
          described_class.new.perform(fresh_artwork)
        }.to raise_error(ThumbnailGenerationService::GenerationError, "Generation failed")
      end

      it "logs error when ThumbnailGenerationService::GenerationError occurs" do
        # Create a fresh artwork to ensure it's eligible
        # Use skip_callback to prevent automatic job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)
        fresh_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Clear any enqueued jobs
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear

        # Ensure the artwork is eligible and doesn't have thumbnail yet
        expect(fresh_artwork.youtube_thumbnail_eligible?).to be true
        expect(fresh_artwork.has_youtube_thumbnail?).to be false

        # Only mock the service to simulate failure
        service = instance_double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service)
        allow(service).to receive(:generate).and_raise(ThumbnailGenerationService::GenerationError, "Generation failed")

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{fresh_artwork.id}")
        expect(Rails.logger).to receive(:error).with("Failed to generate YouTube thumbnail for artwork #{fresh_artwork.id}: Generation failed")

        # Use perform method directly which doesn't trigger retries in test environment
        expect {
          described_class.new.perform(fresh_artwork)
        }.to raise_error(ThumbnailGenerationService::GenerationError, "Generation failed")
      end

      it "logs error when unexpected error occurs" do
        # Create a fresh artwork to ensure it's eligible
        # Use skip_callback to prevent automatic job scheduling
        Artwork.skip_callback(:commit, :after, :schedule_thumbnail_generation)
        fresh_artwork = create(:artwork, content: content, image: fixture_file_upload('images/fhd_placeholder.jpg', 'image/jpeg'))
        Artwork.set_callback(:commit, :after, :schedule_thumbnail_generation)

        # Clear any enqueued jobs
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear

        # Ensure the artwork is eligible and doesn't have thumbnail yet
        expect(fresh_artwork.youtube_thumbnail_eligible?).to be true
        expect(fresh_artwork.has_youtube_thumbnail?).to be false

        # Only mock the service to simulate failure
        service = instance_double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service)
        allow(service).to receive(:generate).and_raise(StandardError, "Unexpected error")

        expect(Rails.logger).to receive(:info).with("Starting derivative processing for artwork #{fresh_artwork.id}")
        expect(Rails.logger).to receive(:error).with("Unexpected error in derivative processing for artwork #{fresh_artwork.id}: Unexpected error")
        expect(Rails.logger).to receive(:error).with(anything) # backtrace

        # Use perform method directly which doesn't trigger retries in test environment
        expect {
          described_class.new.perform(fresh_artwork)
        }.to raise_error(StandardError, "Unexpected error")
      end
    end

    describe "retry configuration" do
      it "retries on ThumbnailGenerationService::GenerationError" do
        retry_config = described_class.retry_on_exception_attempts
        expect(retry_config[ThumbnailGenerationService::GenerationError]).to eq(2)
      end

      it "retries on StandardError" do
        retry_config = described_class.retry_on_exception_attempts
        expect(retry_config[StandardError]).to eq(3)
      end

      it "discards on ActiveRecord::RecordNotFound" do
        discard_classes = described_class.discard_on_exception_classes
        expect(discard_classes).to include(ActiveRecord::RecordNotFound)
      end
    end
  end
end
