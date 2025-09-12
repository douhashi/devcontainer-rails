class Artwork < ApplicationRecord
  include ImageUploader::Attachment(:image)

  belongs_to :content

  validates :image, presence: true

  # Callback to trigger derivative processing for eligible artworks
  after_save :schedule_thumbnail_generation, if: :saved_change_to_image_data?

  def youtube_thumbnail_eligible?
    return false unless image.present?

    begin
      metadata = image.metadata
      return false unless metadata

      width = metadata["width"]
      height = metadata["height"]

      width == 1920 && height == 1080
    rescue => e
      Rails.logger.warn "Failed to check YouTube thumbnail eligibility for artwork #{id}: #{e.message}"
      false
    end
  end

  def has_youtube_thumbnail?
    return false unless image.present?

    derivatives = image_attacher.derivatives
    derivatives && derivatives[:youtube_thumbnail].present?
  rescue => e
    Rails.logger.warn "Failed to check YouTube thumbnail existence for artwork #{id}: #{e.message}"
    false
  end

  def youtube_thumbnail_url
    return nil unless has_youtube_thumbnail?

    image_attacher.derivatives[:youtube_thumbnail].url
  rescue => e
    Rails.logger.warn "Failed to get YouTube thumbnail URL for artwork #{id}: #{e.message}"
    nil
  end

  def youtube_thumbnail_processing?
    # This would require implementing job status tracking
    # For now, we'll return false and implement it later if needed
    false
  end

  def youtube_thumbnail_download_url
    return nil unless has_youtube_thumbnail?

    begin
      base_url = youtube_thumbnail_url
      return nil unless base_url

      filename = "#{content.theme.gsub(/[^a-zA-Z0-9\-_.]/, '_')}_youtube_thumbnail.jpg"
      "#{base_url}?disposition=attachment&filename=#{CGI.escape(filename)}"
    rescue => e
      Rails.logger.warn "Failed to generate YouTube thumbnail download URL for artwork #{id}: #{e.message}"
      nil
    end
  end

  private

  def schedule_thumbnail_generation
    if youtube_thumbnail_eligible? && !has_youtube_thumbnail?
      DerivativeProcessingJob.perform_later(self)
      Rails.logger.info "Scheduled YouTube thumbnail generation for artwork #{id}"
    end
  end
end
