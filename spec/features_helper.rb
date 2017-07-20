require 'rails_helper'
require 'solr_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'
require 'uri'
require 'cgi'

# ------------------------------------------------------------
# Capybara

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(args: ['--incognito'])
  )
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

# ------------------------------------------------------------
# OmniAuth

def mock_omniauth!
  raise "No tenant with id 'localhost'; did you run travis-prep.sh?" unless StashEngine::Tenant.exists?('localhost')

  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(
    :google_oauth2,
    uid: '555555555555555555555',
    credentials: {
      token: 'ya29.Ry4gVGVzdHkgTWNUZXN0ZmFjZQ'
    },
    info: {
      email: 'test@example.edu.test-google-a.com',
      name: 'G. Testy McTestface',
      test_domain: 'localhost'
    }
  )
end

# ------------------------------------------------------------
# RSpec

RSpec.configure do |config|
  # Mock OmniAuth login
  config.before(:suite) do
    mock_omniauth!
    SolrHelper.start
  end

  # Stop Solr when we're done
  config.after(:suite) { SolrHelper.stop }
end

# ------------------------------------------------------------
# Misc. helper methods

def find_blank_field_id(name_or_id)
  field = find_field(name_or_id)
  expect(field.value).to be_blank
  field[:id]
end

def home_page_title
  @home_page_title ||= begin
    home_html_erb = File.read("#{STASH_ENGINE_PATH}/app/views/stash_engine/pages/home.html.erb")
    home_html_erb[/page_title = '([^']+)'/, 1]
  end
end

def current_query_parameters
  query_string = current_url && URI(current_url).query
  query_string && CGI.parse(query_string)
end

def current_resource_id
  current_query_parameters['resource_id']
end

# From https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
def wait_for_ajax!
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.evaluate_script('jQuery.active').zero?
  end
end
