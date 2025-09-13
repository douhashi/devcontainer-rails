require 'selenium-webdriver'
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

# Only configure remote driver if SELENIUM_URL is present (for Docker environments)
if ENV['SELENIUM_URL']
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--no-sandbox')
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1680,1050')

    url = ENV.fetch("SELENIUM_URL", "http://localhost:4444/wd/hub")

    Capybara::Selenium::Driver.new(app, browser: :remote, url: url, capabilities: options)
  end

  Capybara.server_host = IPSocket.getaddress(Socket.gethostname)
  Capybara.server_port = 5555
  Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"

  RSpec.configure do |config|
    config.include Capybara::DSL

    # Select driver based on environment variable or tag
    config.before(:each, type: :system) do |example|
      if ENV['CAPYBARA_DRIVER'] == 'playwright' || example.metadata[:playwright]
        driven_by :playwright
      else
        driven_by :chrome
      end
    end

    config.before(:each, type: :system, js: true) do |example|
      if ENV['CAPYBARA_DRIVER'] == 'playwright' || example.metadata[:playwright]
        driven_by :playwright
      else
        driven_by :chrome
      end
    end
  end
else
  # Use the driver configured in rails_helper.rb for local and CI environments
  RSpec.configure do |config|
    config.include Capybara::DSL

    # Select driver based on environment variable or tag
    config.before(:each, type: :system) do |example|
      if ENV['CAPYBARA_DRIVER'] == 'playwright' || example.metadata[:playwright]
        driven_by :playwright
      else
        driven_by :selenium_chrome_headless
      end
    end

    config.before(:each, type: :system, js: true) do |example|
      if ENV['CAPYBARA_DRIVER'] == 'playwright' || example.metadata[:playwright]
        driven_by :playwright
      else
        driven_by :selenium_chrome_headless
      end
    end
  end
end
