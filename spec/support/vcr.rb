require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  # Filter sensitive data
  config.filter_sensitive_data('<KIE_AI_API_KEY>') { ENV.fetch('KIE_AI_API_KEY', '') }

  # Allow recording new cassettes
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [ :method, :uri, :body ]
  }

  # Ignore localhost requests (for Selenium/Capybara)
  config.ignore_localhost = true
end
