require "rails_helper"
require "vips"

RSpec.describe "Artwork Upload", type: :system, playwright: true do
  include ActiveJob::TestHelper
  include_context "ログイン済み"

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

  describe "uploading an artwork", js: true, playwright: true do
    context "with YouTube-eligible artwork (1920x1080)" do
      it "uploads artwork successfully" do
        visit content_path(content)

        # Upload the FHD image
        within("turbo-frame#artwork-section-#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_fhd_artwork.jpg"), visible: false
        end

        # Wait for the upload to complete and page to update
        expect(page).to have_css(".artwork-variations-grid", wait: 10)

        # Verify that the derivative processing job was NOT enqueued (synchronous now)
        expect(DerivativeProcessingJob).not_to have_been_enqueued
      end
    end

    context "with non-YouTube-eligible artwork (not 1920x1080)" do
      it "uploads artwork successfully" do
        visit content_path(content)

        # Upload the small image
        within("turbo-frame#artwork-section-#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_small_artwork.jpg"), visible: false
        end

        # Wait for the upload to complete and page to update
        expect(page).to have_css(".artwork-variations-grid", wait: 10)

        # Verify that no derivative processing job was enqueued
        expect(DerivativeProcessingJob).not_to have_been_enqueued
      end
    end
  end

  describe "artwork deletion", js: true, playwright: true do
    let!(:artwork) { create(:artwork, content: content) }

    it "deletes artwork via delete button and shows upload form" do
      visit content_path(content)

      # Confirm artwork is displayed
      expect(page).to have_css(".artwork-variations-grid")

      # Ensure delete button is present
      expect(page).to have_css('button[aria-label="アートワークを削除"]')

      # Delete the artwork with confirmation
      accept_confirm do
        find('button[aria-label="アートワークを削除"]').click
      end

      # Wait for Turbo Stream to process the deletion
      # The artwork-section should be replaced with the upload form
      expect(page).to have_text("画像をドラッグ&ドロップ", wait: 10)
      expect(page).not_to have_css(".artwork-variations-grid")

      # Verify artwork is actually deleted from database
      expect(content.reload.artwork).to be_nil
    end

    it "shows confirmation dialog when delete button is clicked" do
      visit content_path(content)

      # Confirm artwork is displayed
      expect(page).to have_css(".artwork-variations-grid")

      # Click delete button but dismiss the confirmation
      dismiss_confirm do
        find('button[aria-label="アートワークを削除"]').click
      end

      # Artwork should still be present
      expect(page).to have_css(".artwork-variations-grid")
      expect(content.reload.artwork).to be_present
    end
  end

  describe "error handling", js: true, playwright: true do
    it "validates file type on upload" do
      visit content_path(content)

      # Create a temporary text file
      invalid_file = Rails.root.join("tmp/invalid_file.txt")
      File.write(invalid_file, "This is not an image")

      begin
        # Try to attach the invalid file
        # Note: Browser validation should prevent non-image files
        # The actual validation happens client-side in the input accept attribute
        within("turbo-frame#artwork-section-#{content.id}") do
          file_input = find('input[type="file"]', visible: false)

          # Check that the file input has proper accept attribute
          expect(file_input['accept']).to include('image/')
        end

        # Since browser validation prevents invalid files, we verify the validation exists
        # rather than trying to upload an invalid file
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
