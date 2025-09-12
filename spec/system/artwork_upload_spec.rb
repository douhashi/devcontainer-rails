require "rails_helper"

RSpec.describe "Artwork Upload", type: :system do
  include ActiveJob::TestHelper

  let(:content) { create(:content) }

  before do
    # Create test images
    create_test_fhd_image(Rails.root.join("tmp/test_fhd_artwork.jpg"))
    create_test_small_image(Rails.root.join("tmp/test_small_artwork.jpg"))
  end

  after do
    # Clean up test files
    FileUtils.rm_f(Rails.root.join("tmp/test_fhd_artwork.jpg"))
    FileUtils.rm_f(Rails.root.join("tmp/test_small_artwork.jpg"))
  end

  describe "uploading an artwork", js: true do
    context "with YouTube-eligible artwork (1920x1080)" do
      it "uploads artwork and shows YouTube thumbnail status" do
        visit content_path(content)

        # Upload the FHD image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_fhd_artwork.jpg")
        end

        # Wait for the upload to complete and page to update
        expect(page).to have_css("img[alt='アートワーク']")

        # Check if YouTube status is shown
        expect(page).to have_content("YouTube対応")

        # Verify that the derivative processing job was enqueued
        expect(DerivativeProcessingJob).to have_been_enqueued
      end
    end

    context "with non-YouTube-eligible artwork (not 1920x1080)" do
      it "uploads artwork without YouTube thumbnail status" do
        visit content_path(content)

        # Upload the small image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_small_artwork.jpg")
        end

        # Wait for the upload to complete and page to update
        expect(page).to have_css("img[alt='アートワーク']")

        # Check that YouTube status is NOT shown for non-eligible images
        expect(page).not_to have_content("YouTube対応")

        # Verify that no derivative processing job was enqueued
        expect(DerivativeProcessingJob).not_to have_been_enqueued
      end
    end
  end

  describe "YouTube thumbnail functionality", js: true do
    let(:artwork) { create(:artwork, content: content) }

    before do
      # Mock the artwork to be YouTube-eligible
      allow(artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)

      # Visit the page with existing artwork
      visit content_path(content)
    end

    context "when thumbnail generation is complete" do
      before do
        # Mock that the thumbnail exists
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(true)
        allow(artwork).to receive(:youtube_thumbnail_download_url).and_return("http://example.com/thumbnail.jpg?disposition=attachment")

        # Re-render the page with updated artwork state
        visit current_path
      end

      it "shows download link for generated thumbnail" do
        expect(page).to have_link("サムネイル", href: /thumbnail\.jpg/)
        expect(page).to have_content("YouTube対応")
      end
    end

    context "when thumbnail generation is in progress" do
      before do
        # Mock processing state
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
        allow(artwork).to receive(:youtube_thumbnail_processing?).and_return(true)

        visit current_path
      end

      it "shows processing status" do
        expect(page).to have_content("サムネイル生成中")
      end
    end

    context "when thumbnail has not been generated yet" do
      before do
        allow(artwork).to receive(:has_youtube_thumbnail?).and_return(false)
        allow(artwork).to receive(:youtube_thumbnail_processing?).and_return(false)

        visit current_path
      end

      it "shows eligible status without download link" do
        expect(page).to have_content("YouTube対応")
        expect(page).not_to have_link("サムネイル")
      end
    end
  end

  describe "artwork deletion", js: true do
    let!(:artwork) { create(:artwork, content: content) }

    it "deletes artwork and removes YouTube thumbnail status" do
      visit content_path(content)

      # Confirm artwork is displayed
      expect(page).to have_css("img[alt='アートワーク']")

      # Delete the artwork
      accept_confirm do
        within("turbo-frame#artwork_#{content.id}") do
          click_button "削除"
        end
      end

      # Wait for deletion to complete
      expect(page).not_to have_css("img[alt='アートワーク']")
      expect(page).not_to have_content("YouTube対応")
    end
  end

  describe "error handling", js: true do
    it "shows error message for invalid file upload" do
      visit content_path(content)

      # Try to upload an invalid file (text file)
      invalid_file = Rails.root.join("tmp/invalid_file.txt")
      File.write(invalid_file, "This is not an image")

      begin
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", invalid_file
        end

        # Should show error message
        expect(page).to have_content(/アップロードに失敗/)
      ensure
        FileUtils.rm_f(invalid_file)
      end
    end
  end

  private

  def create_test_fhd_image(path)
    image = Vips::Image.black(1920, 1080, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path.to_s, Q: 90)
  end

  def create_test_small_image(path)
    image = Vips::Image.black(800, 600, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path.to_s, Q: 90)
  end
end
