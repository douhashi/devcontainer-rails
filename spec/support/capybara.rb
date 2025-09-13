require 'capybara-playwright-driver'

# Register Playwright driver
Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true,
    viewport: { width: 1680, height: 1050 }
  )
end

# Register Playwright driver with options for debugging
Capybara.register_driver :playwright_debug do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: false,
    viewport: { width: 1680, height: 1050 },
    devtools: true
  )
end

RSpec.configure do |config|
  config.include Capybara::DSL

  # Use Playwright driver for all system tests
  config.before(:each, type: :system) do
    driven_by :playwright
  end

  config.before(:each, type: :system, js: true) do
    driven_by :playwright
  end
end
