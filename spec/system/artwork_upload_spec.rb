require "rails_helper"
require "vips"

RSpec.describe "Artwork Upload", type: :system do
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

  describe "uploading an artwork", js: true do
    context "with YouTube-eligible artwork (1920x1080)" do
      it "uploads artwork and shows YouTube thumbnail status" do
        visit content_path(content)

        # Upload the FHD image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_fhd_artwork.jpg"), visible: false
        end

        # Wait for the upload to complete and page to update
        expect(page).to have_css("img[alt='アートワーク']")

        # Check if YouTube status is shown
        expect(page).to have_content("YouTube対応")

        # Verify that the derivative processing job was enqueued
        expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
      end
    end

    context "with non-YouTube-eligible artwork (not 1920x1080)" do
      it "uploads artwork without YouTube thumbnail status" do
        visit content_path(content)

        # Upload the small image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_small_artwork.jpg"), visible: false
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
    context "when uploading FHD artwork" do
      it "shows YouTube eligibility status" do
        visit content_path(content)

        # Upload the FHD image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_fhd_artwork.jpg"), visible: false
        end

        # Wait for the upload to complete
        expect(page).to have_css("img[alt='アートワーク']")

        # Check if YouTube status is shown for eligible images
        expect(page).to have_content("YouTube対応")
      end
    end

    context "when uploading non-FHD artwork" do
      it "does not show YouTube eligibility status" do
        visit content_path(content)

        # Upload the small image
        within("turbo-frame#artwork_#{content.id}") do
          attach_file "artwork[image]", Rails.root.join("tmp/test_small_artwork.jpg"), visible: false
        end

        # Wait for the upload to complete
        expect(page).to have_css("img[alt='アートワーク']")

        # Check that YouTube status is NOT shown for non-eligible images
        expect(page).not_to have_content("YouTube対応")
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
          find('button[aria-label="削除"]').click
        end
      end

      # Wait for deletion to complete
      expect(page).not_to have_css("img[alt='アートワーク']")
      expect(page).not_to have_content("YouTube対応")
    end
  end

  describe "thumbnail status display", js: true do
    context "when thumbnail generation is pending" do
      let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :pending) }

      it "shows pending status badge" do
        visit content_path(content)

        within("turbo-frame#artwork_#{content.id}") do
          expect(page).to have_content("未生成")
          expect(page).to have_css(".bg-gray-600.text-gray-200")
        end
      end
    end

    context "when thumbnail generation is processing" do
      let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :processing) }

      it "shows processing status badge with spinner" do
        visit content_path(content)

        within("turbo-frame#artwork_#{content.id}") do
          expect(page).to have_content("生成中")
          expect(page).to have_css(".bg-yellow-600.text-yellow-200")
          expect(page).to have_css("svg.animate-spin")
        end
      end

      it "does not show regenerate button when processing" do
        visit content_path(content)

        within("turbo-frame#artwork_#{content.id}") do
          expect(page).not_to have_button("再生成")
        end
      end
    end

    context "when thumbnail generation is completed" do
      let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :completed) }

      it "shows completed status badge" do
        visit content_path(content)

        within("turbo-frame#artwork_#{content.id}") do
          expect(page).to have_content("生成済み")
          expect(page).to have_css(".bg-green-600.text-green-200")
          expect(page).not_to have_css("svg.animate-spin")
        end
      end
    end

    context "when thumbnail generation failed" do
      let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed, thumbnail_generation_error: "Test error") }

      it "shows failed status badge with error details" do
        visit content_path(content)

        within("turbo-frame#artwork_#{content.id}") do
          expect(page).to have_content("失敗")
          expect(page).to have_css(".bg-red-600.text-red-200")
          expect(page).to have_css("span[title='Test error']")
        end
      end
    end
  end

  describe "thumbnail regeneration", js: true do
    let!(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed, thumbnail_generation_error: "Test error") }

    before do
      # Mock the artwork to be YouTube eligible
      allow_any_instance_of(Artwork).to receive(:youtube_thumbnail_eligible?).and_return(true)
    end

    it "allows regenerating thumbnails for failed artwork" do
      visit content_path(content)

      within("turbo-frame#artwork_#{content.id}") do
        expect(page).to have_content("失敗")
        expect(page).to have_button("再生成")

        accept_confirm do
          click_button "再生成"
        end
      end

      # Wait for the status to update to pending after regeneration starts
      within("turbo-frame#artwork_#{content.id}") do
        expect(page).to have_content("未生成")
      end

      # Verify that the derivative processing job was enqueued
      expect(DerivativeProcessingJob).to have_been_enqueued.at_least(:once)
    end
  end

  describe "error handling", js: true do
    it "validates file type on upload" do
      visit content_path(content)

      # Create a temporary text file
      invalid_file = Rails.root.join("tmp/invalid_file.txt")
      File.write(invalid_file, "This is not an image")

      begin
        # Try to attach the invalid file
        # Note: Browser validation should prevent non-image files
        # The actual validation happens client-side in the input accept attribute
        within("turbo-frame#artwork_#{content.id}") do
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
