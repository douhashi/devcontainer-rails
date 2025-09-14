class Artwork < ApplicationRecord
  include ImageUploader::Attachment(:image)

  belongs_to :content

  validates :image, presence: true

  enum :thumbnail_generation_status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, prefix: true

  VARIATION_TYPES = {
    original: "オリジナル",
    youtube_thumbnail: "YouTube用",
    square: "正方形",
    banner: "バナー"
  }.freeze

  # Callback to trigger derivative processing for eligible artworks
  # Use after_commit to ensure the record is saved to the database before job is enqueued
  # NOTE: Disabled as thumbnail generation is now handled synchronously in controller
  # after_commit :schedule_thumbnail_generation, on: [ :create, :update ], if: :saved_change_to_image_data?

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
    thumbnail_generation_status_processing?
  end

  def mark_thumbnail_generation_started!
    update!(
      thumbnail_generation_status: :processing,
      thumbnail_generation_error: nil
    )
  end

  def mark_thumbnail_generation_completed!
    update!(
      thumbnail_generation_status: :completed,
      thumbnail_generation_error: nil,
      thumbnail_generated_at: Time.current
    )
  end

  def mark_thumbnail_generation_failed!(error_message)
    update!(
      thumbnail_generation_status: :failed,
      thumbnail_generation_error: error_message
    )
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

  def all_variations
    variations = []

    # Original image is always present
    if image.present?
      variations << {
        type: :original,
        label: VARIATION_TYPES[:original],
        url: image.url,
        metadata: original_metadata,
        download_url: original_download_url
      }
    end

    # YouTube thumbnail if exists
    if has_youtube_thumbnail?
      variations << {
        type: :youtube_thumbnail,
        label: VARIATION_TYPES[:youtube_thumbnail],
        url: youtube_thumbnail_url,
        metadata: youtube_thumbnail_metadata,
        download_url: youtube_thumbnail_download_url
      }
    end

    # Future variations can be added here
    # if has_square_thumbnail?
    #   variations << {
    #     type: :square,
    #     label: VARIATION_TYPES[:square],
    #     url: square_thumbnail_url,
    #     metadata: square_thumbnail_metadata,
    #     download_url: square_thumbnail_download_url
    #   }
    # end

    variations
  end

  def variation_metadata(type)
    case type
    when :original
      original_metadata
    when :youtube_thumbnail
      youtube_thumbnail_metadata
    else
      {}
    end
  end

  def has_variation?(type)
    case type
    when :original
      image.present?
    when :youtube_thumbnail
      has_youtube_thumbnail?
    when :square, :banner
      # Future variations
      false
    else
      false
    end
  end

  private

  def original_metadata
    return {} unless image.present?

    begin
      metadata = image.metadata
      return {} unless metadata

      {
        width: metadata["width"],
        height: metadata["height"],
        size: image.size
      }
    rescue => e
      Rails.logger.warn "Failed to get original metadata for artwork #{id}: #{e.message}"
      {}
    end
  end

  def original_download_url
    return nil unless image.present?

    begin
      filename = "#{content.theme.gsub(/[^a-zA-Z0-9\-_.]/, '_')}_original.jpg"
      "#{image.url}?disposition=attachment&filename=#{CGI.escape(filename)}"
    rescue => e
      Rails.logger.warn "Failed to generate original download URL for artwork #{id}: #{e.message}"
      nil
    end
  end

  def youtube_thumbnail_metadata
    return {} unless has_youtube_thumbnail?

    {
      width: 1280,
      height: 720,
      size: nil # Size information would need to be stored or calculated
    }
  end

  def schedule_thumbnail_generation
    begin
      Rails.logger.debug "Checking thumbnail generation eligibility for artwork #{id}"
      Rails.logger.debug "Image present: #{image.present?}"
      Rails.logger.debug "Image metadata: #{image.metadata.inspect}" if image.present?

      if youtube_thumbnail_eligible?
        Rails.logger.info "Artwork #{id} is eligible for YouTube thumbnail generation"

        if has_youtube_thumbnail?
          Rails.logger.info "Artwork #{id} already has YouTube thumbnail, skipping generation"
        else
          DerivativeProcessingJob.perform_later(self)
          Rails.logger.info "Scheduled YouTube thumbnail generation for artwork #{id}"
        end
      else
        Rails.logger.debug "Artwork #{id} is not eligible for YouTube thumbnail generation"
      end
    rescue => e
      Rails.logger.error "Failed to schedule thumbnail generation for artwork #{id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
