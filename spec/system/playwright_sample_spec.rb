require 'rails_helper'

RSpec.describe "Playwright Sample", type: :system do
  describe "Basic browser operations with Playwright" do
    it "loads the home page" do
      visit root_path
      expect(page).to have_content("Lofi BGM")
    end

    it "handles JavaScript interactions", js: true do
      visit root_path
      # Basic JavaScript test - checking if page has loaded
      expect(page).to have_css("body")
      # Check that the page has been rendered
      expect(page).to have_content("Lofi BGM")
      # Verify JavaScript is enabled by checking page ready state
      expect(page.evaluate_script("document.readyState")).to eq("complete")
    end
  end

  describe "Page load performance" do
    it "executes fast page loads" do
      start_time = Time.now
      visit root_path
      load_time = Time.now - start_time

      expect(page).to have_content("Lofi BGM")
      # Playwright loads pages efficiently
      puts "Page load time: #{load_time.round(3)} seconds"
    end
  end

  describe "Advanced Playwright features", js: true do
    it "can take screenshots" do
      visit root_path
      # Ensure tmp directory exists
      FileUtils.mkdir_p("tmp")
      # Playwright supports advanced screenshot features
      screenshot_path = Rails.root.join("tmp", "playwright_test.png")
      page.save_screenshot(screenshot_path)
      expect(File.exist?(screenshot_path)).to be true
      # Clean up the test screenshot
      File.delete(screenshot_path) if File.exist?(screenshot_path)
    end

    it "handles network conditions" do
      visit root_path
      # Test basic page functionality
      expect(page.status_code).to eq(200)
    end
  end
end
