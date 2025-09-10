require 'selenium-webdriver'

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
    config.before(:each, type: :system) do
      driven_by :chrome
    end

    config.before(:each, type: :system, js: true) do
      driven_by :chrome
    end
  end
else
  # Use the driver configured in rails_helper.rb for local and CI environments
  RSpec.configure do |config|
    config.include Capybara::DSL
    config.before(:each, type: :system) do
      driven_by :selenium_chrome_headless
    end

    config.before(:each, type: :system, js: true) do
      driven_by :selenium_chrome_headless
    end
  end
end
