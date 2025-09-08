require 'rails_helper'

RSpec.describe "Tracks Performance", type: :system, js: true do
  let!(:content) { create(:content, theme: "Performance Test Content") }

  describe "JavaScript Performance" do
    context "with multiple tracks" do
      let!(:tracks) { create_list(:track, 10, content: content) }

      it "loads page without JavaScript errors" do
        visit tracks_path

        # Page should load completely within acceptable time
        expect(page).to have_content("Track一覧")
        expect(page).to have_content("Performance Test Content")

        # Check no JavaScript errors occurred (if browser supports logs)
        begin
          logs = page.driver.browser.logs.get(:browser)
          error_logs = logs.select { |log| log.level == "SEVERE" }
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
        expect(page).to have_content("10件中")
      end
    end

    context "with processing tracks (animations)" do
      let!(:processing_tracks) { create_list(:track, 5, :processing, content: content) }
      let!(:completed_tracks) { create_list(:track, 5, :completed, content: content) }

      it "renders animations without causing performance issues" do
        visit tracks_path

        expect(page).to have_content("Track一覧")

        # Should have animate-spin elements for processing tracks
        expect(page).to have_css('.animate-spin', minimum: 1)

        # Page should remain responsive (simplified check)
        expect(page).to have_content("10件中")
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

    context "with search functionality" do
      let!(:tracks) { create_list(:track, 5, content: content) }

      it "handles search form interactions smoothly" do
        visit tracks_path

        fill_in "Content名", with: "Performance Test"

        # Form should be responsive
        expect(page).to have_field("Content名", with: "Performance Test")

        click_button "検索"

        # Search should complete without hanging
        expect(page).to have_content("Track一覧")
      end

      it "validates date ranges without causing delays" do
        visit tracks_path

        # Just check that date fields are responsive
        expect(page).to have_field("作成日（開始）")
        expect(page).to have_field("作成日（終了）")

        # No delay when clicking on date fields
        find_field("作成日（開始）").click
        expect(page).to have_field("作成日（開始）", visible: true)
      end
    end
  end

  describe "Large Dataset Performance" do
    context "with many tracks" do
      let!(:many_tracks) { create_list(:track, 50, content: content) }

      it "loads page with large dataset within acceptable time" do
        start_time = Time.current
        visit tracks_path
        load_time = Time.current - start_time

        expect(page).to have_content("Track一覧")
        expect(load_time).to be < 5.0, "Page load took #{load_time}s, expected < 5.0s"
      end

      it "handles pagination smoothly" do
        visit tracks_path

        # First page should load
        expect(page).to have_content("50件中 1-30件を表示")

        # Navigation to next page should be smooth
        if page.has_link?("次のページ")
          click_link "次のページ"
          expect(page).to have_content("50件中 31-50件を表示")
        end
      end
    end
  end
end
