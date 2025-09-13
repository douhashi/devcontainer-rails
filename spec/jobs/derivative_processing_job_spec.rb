require "rails_helper"
require "vips"

RSpec.describe DerivativeProcessingJob, type: :job do
  include ActiveJob::TestHelper

  let(:artwork) { create(:artwork) }

  describe "#perform" do
    context "with valid artwork" do
      before do
        # Mock the image download to return a tempfile
        tempfile_double = double(path: "/tmp/test_image.jpg", close: nil, unlink: nil)
        allow(artwork.image).to receive(:download).and_return(tempfile_double)
        allow(File).to receive(:exist?).and_return(true)
        allow(artwork).to receive(:persisted?).and_return(true)
        allow(artwork.image).to receive(:present?).and_return(true)
      end

      it "calls ThumbnailGenerationService to generate thumbnail" do
        service_double = double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:generate).and_return({
          input_size: { width: 1920, height: 1080 },
          output_size: { width: 1280, height: 720 },
          file_size: 125000
        })

        # Mock the derivative assignment is handled by attacher_double

        subject.perform(artwork)

        expect(ThumbnailGenerationService).to have_received(:new)
        expect(service_double).to have_received(:generate)
      end

      it "assigns the generated thumbnail as a derivative" do
        # Use real artwork with FHD image
        artwork = create(:artwork)

        # Create a real FHD test image
        test_image_path = Rails.root.join("tmp/test_fhd_#{SecureRandom.hex}.jpg")
        image = Vips::Image.black(1920, 1080, bands: 3)
        image = image.add(128)
        image.write_to_file(test_image_path.to_s, Q: 90)

        # Upload the image to artwork
        artwork.image = File.open(test_image_path)
        artwork.save!

        service_double = double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:generate).and_return({
          input_size: { width: 1920, height: 1080 },
          output_size: { width: 1280, height: 720 },
          file_size: 125000
        })

        # Spy on derivative creation
        attacher = artwork.image_attacher
        allow(attacher).to receive(:create_derivatives).and_call_original

        subject.perform(artwork)

        expect(attacher).to have_received(:create_derivatives)

        # Cleanup
        FileUtils.rm_f(test_image_path)
      end

      it "logs successful thumbnail generation" do
        # Use real artwork with FHD image
        artwork = create(:artwork)

        # Create a real FHD test image
        test_image_path = Rails.root.join("tmp/test_fhd_#{SecureRandom.hex}.jpg")
        image = Vips::Image.black(1920, 1080, bands: 3)
        image = image.add(128)
        image.write_to_file(test_image_path.to_s, Q: 90)

        # Upload the image to artwork
        artwork.image = File.open(test_image_path)
        artwork.save!

        service_double = double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:generate).and_return({
          input_size: { width: 1920, height: 1080 },
          output_size: { width: 1280, height: 720 },
          file_size: 125000
        })

        allow(Rails.logger).to receive(:info)

        subject.perform(artwork)

        expect(Rails.logger).to have_received(:info).with(/Successfully generated YouTube thumbnail for artwork/)

        # Cleanup
        FileUtils.rm_f(test_image_path)
      end
    end

    context "when artwork record is not found" do
      it "logs the error and discards the job" do
        non_existent_artwork = double(id: 999)
        allow(non_existent_artwork).to receive(:persisted?).and_return(false)
        allow(Rails.logger).to receive(:warn)

        subject.perform(non_existent_artwork)

        expect(Rails.logger).to have_received(:warn).with(/Artwork record not found or has been deleted/)
      end
    end

    context "when image file is missing" do
      before do
        tempfile_double = double(path: "/tmp/missing_image.jpg", close: nil, unlink: nil)
        allow(artwork.image).to receive(:download).and_return(tempfile_double)
        allow(File).to receive(:exist?).and_return(false)
        allow(artwork).to receive(:persisted?).and_return(true)
        allow(artwork.image).to receive(:present?).and_return(true)
      end

      it "logs the error and discards the job" do
        allow(Rails.logger).to receive(:error)

        subject.perform(artwork)

        expect(Rails.logger).to have_received(:error).with(/Image file not found/)
      end
    end

    context "when ThumbnailGenerationService raises GenerationError" do
      before do
        tempfile_double = double(path: "/tmp/test_image.jpg", close: nil, unlink: nil)
        allow(artwork.image).to receive(:download).and_return(tempfile_double)
        allow(File).to receive(:exist?).and_return(true)
        allow(artwork).to receive(:persisted?).and_return(true)
        allow(artwork.image).to receive(:present?).and_return(true)
      end

      it "retries the job when generation error occurs" do
        service_double = double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:generate).and_raise(ThumbnailGenerationService::GenerationError, "Test generation error")

        allow(Rails.logger).to receive(:error)

        expect { subject.perform(artwork) }.to raise_error(ThumbnailGenerationService::GenerationError)
        expect(Rails.logger).to have_received(:error).with(/Failed to generate YouTube thumbnail/)
      end
    end

    context "when unexpected error occurs" do
      before do
        tempfile_double = double(path: "/tmp/test_image.jpg", close: nil, unlink: nil)
        allow(artwork.image).to receive(:download).and_return(tempfile_double)
        allow(File).to receive(:exist?).and_return(true)
        allow(artwork).to receive(:persisted?).and_return(true)
        allow(artwork.image).to receive(:present?).and_return(true)
      end

      it "retries the job when unexpected error occurs" do
        service_double = double(ThumbnailGenerationService)
        allow(ThumbnailGenerationService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:generate).and_raise(StandardError, "Unexpected error")

        allow(Rails.logger).to receive(:error)

        expect { subject.perform(artwork) }.to raise_error(StandardError)
        expect(Rails.logger).to have_received(:error).with(/Unexpected error in derivative processing/)
      end
    end
  end

  describe "retry behavior" do
    it "has defined retry behavior for ThumbnailGenerationService::GenerationError" do
      expect(DerivativeProcessingJob.retry_on_exception_attempts[ThumbnailGenerationService::GenerationError]).to eq(2)
    end

    it "has defined retry behavior for StandardError" do
      expect(DerivativeProcessingJob.retry_on_exception_attempts[StandardError]).to eq(3)
    end

    it "has defined discard behavior for ActiveRecord::RecordNotFound" do
      expect(DerivativeProcessingJob.discard_on_exception_classes).to include(ActiveRecord::RecordNotFound)
    end
  end
end
