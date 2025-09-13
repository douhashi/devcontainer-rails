class DerivativeProcessingJob < ApplicationJob
  queue_as :default

  # Retry configuration for different types of errors
  retry_on ThumbnailGenerationService::GenerationError, wait: :exponentially_longer, attempts: 2
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Discard job if record is no longer available
  discard_on ActiveRecord::RecordNotFound

  def perform(artwork)
    Rails.logger.info "Starting derivative processing for artwork #{artwork.id}"

    # Check if artwork record still exists and is valid
    unless artwork.persisted? && artwork.image.present?
      Rails.logger.warn "Artwork record not found or has been deleted: #{artwork.id}"
      return
    end

    # Check if image file exists
    # Download the image to a temporary file for processing
    tempfile = artwork.image.download
    image_path = tempfile.path
    unless image_path && File.exist?(image_path)
      Rails.logger.error "Image file not found for artwork #{artwork.id}: #{image_path}"
      tempfile.close if tempfile
      tempfile.unlink if tempfile && tempfile.path
      return
    end

    # Generate YouTube thumbnail using ThumbnailGenerationService
    begin
      service = ThumbnailGenerationService.new

      # Create temporary output file for thumbnail
      output_file = Tempfile.new([ "youtube_thumbnail_#{artwork.id}", ".jpg" ])

      begin
        # Generate thumbnail
        result = service.generate(
          input_path: image_path,
          output_path: output_file.path
        )

        # Create derivatives using Shrine's derivatives plugin
        File.open(output_file.path) do |file|
          attacher = artwork.image_attacher
          attacher.create_derivatives({
            youtube_thumbnail: file
          })
        end

        Rails.logger.info "Successfully generated YouTube thumbnail for artwork #{artwork.id}: #{result}"
      ensure
        # Clean up temporary files
        output_file.close if output_file
        output_file.unlink if output_file && output_file.path && File.exist?(output_file.path)
        tempfile.close if tempfile
        tempfile.unlink if tempfile && tempfile.path && File.exist?(tempfile.path)
      end

    rescue ThumbnailGenerationService::GenerationError => e
      Rails.logger.error "Failed to generate YouTube thumbnail for artwork #{artwork.id}: #{e.message}"
      raise # This will trigger retry
    rescue => e
      Rails.logger.error "Unexpected error in derivative processing for artwork #{artwork.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise # This will trigger retry
    end
  end

  # Class method to access retry configuration for testing
  def self.retry_on_exception_attempts
    @@retry_on_exception_attempts ||= {
      ThumbnailGenerationService::GenerationError => 2,
      StandardError => 3
    }
  end

  def self.discard_on_exception_classes
    @@discard_on_exception_classes ||= [ ActiveRecord::RecordNotFound ]
  end
end
