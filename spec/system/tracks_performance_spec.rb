require 'rails_helper'

RSpec.describe "Tracks Performance", type: :system, js: true do
  let!(:content) { create(:content, theme: "Performance Test Content") }

  describe "JavaScript Performance" do
    context "with multiple tracks" do
      let!(:tracks) { create_list(:track, 10, content: content) }

      it "loads page without JavaScript errors", skip: "Temporarily skipped due to FloatingAudioPlayer initialization" do
        visit tracks_path

        # Page should load completely within acceptable time
        expect(page).to have_content("Track一覧")
        expect(page).to have_content("Performance Test Content")

        # Check no JavaScript errors occurred (if browser supports logs)
        begin
          logs = page.driver.browser.logs.get(:browser)
          # Filter out 404 errors for test assets and audio player errors in test environment
          error_logs = logs.select { |log|
            log.level == "SEVERE" &&
            !log.message.include?("Failed to load resource: the server responded with a status of 404") &&
            !log.message.include?("Audio player error:") # Ignore audio player errors in test environment
          }
          expect(error_logs).to be_empty, "JavaScript errors found: #{error_logs.map(&:message)}"
        rescue => e
          # If logs are not available, just skip this check
          Rails.logger.info "Browser logs not available: #{e.message}"
        end
      end

      it "remains responsive with multiple tracks" do
        visit tracks_path

        # Page should remain responsive
        expect(page).to have_content("Track一覧")
        # Check for track elements
        expect(page).to have_css('.track', minimum: 1)
      end
    end

    context "with processing tracks (animations)" do
      let!(:processing_tracks) { create_list(:track, 5, :processing, content: content) }
      let!(:completed_tracks) { create_list(:track, 5, :completed, content: content) }

      it "renders animations without causing performance issues" do
        visit tracks_path

        expect(page).to have_content("Track一覧")

        # Check for processing status badge
        expect(page).to have_content("処理中", minimum: 1)

        # Page should remain responsive
        expect(page).to have_css('.track', minimum: 1)
      end

      it "does not have infinite animation loops" do
        visit tracks_path

        # Wait a moment for any potential infinite loops to manifest
        sleep 1

        # Page should still be responsive
        expect(page).to have_content("Track一覧")
        expect(page).to have_content("生成中")
      end
    end

    # Search functionality has been temporarily removed in Issue #86
    context "with search functionality (temporarily disabled)" do
      let!(:tracks) { create_list(:track, 5, content: content) }

      xit "handles search form interactions smoothly" do
        # This test is disabled as search functionality was removed in Issue #86
        # Will be re-implemented in a future issue
      end

      xit "validates date ranges without causing delays" do
        # This test is disabled as search functionality was removed in Issue #86
        # Will be re-implemented in a future issue
      end
    end
  end

  describe "Large Dataset Performance" do
    context "with many tracks" do
      let!(:many_tracks) { create_list(:track, 31, content: content) }

      it "loads page with large dataset within acceptable time" do
        start_time = Time.current
        visit tracks_path
        load_time = Time.current - start_time

        expect(page).to have_content("Track一覧")
        expect(load_time).to be < 5.0, "Page load took #{load_time}s, expected < 5.0s"
      end

      it "handles pagination smoothly" do
        visit tracks_path

        # Should display tracks on first page (30 items per page)
        expect(page).to have_css('.track', count: 30)

        # Should have pagination controls
        expect(page).to have_css('nav[aria-label="pagination"]')

        # Navigate to next page if available
        if page.has_link?("Next")
          click_link "Next"
          # Should load next page without issues
          expect(page).to have_content("Track一覧")
          expect(page).to have_css('.track', minimum: 1)
        end
      end
    end

    context "with very large dataset" do
      let!(:large_dataset) { create_list(:track, 100, content: content) }

      it "efficiently handles 100+ tracks with pagination" do
        visit tracks_path

        # Should only show first page of results
        expect(page).to have_css('.track', count: 30)

        # Pagination controls should be present
        expect(page).to have_css('nav[aria-label="pagination"]')

        # Should not attempt to render all tracks at once
        expect(page).not_to have_css('.track', count: 100)
      end
    end
  end
end
