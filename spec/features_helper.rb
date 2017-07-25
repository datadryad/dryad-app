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
# Capybara helpers

def find_field_id(name_or_id)
  field = find_field(name_or_id)
  field[:id]
end

def find_blank_field_id(name_or_id)
  field = find_field(name_or_id)
  expect(field.value).to be_blank
  field[:id]
end

def current_query_parameters
  query_string = current_url && URI(current_url).query
  query_string && CGI.parse(query_string)
end

# From https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
def wait_for_ajax!
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.evaluate_script('jQuery.active').zero?
  end
end

# ------------------------------------------------------------
# Application state helpers

def current_resource_id
  query_params = current_query_parameters
  resource_id_param = query_params && query_params['resource_id']
  return resource_id_param if resource_id_param

  match_data = current_url.match(%r{/resources/([0-9]+)/})
  match_data && match_data[1]
end

def current_resource
  resource_id = current_resource_id
  resource_id && StashEngine::Resource.find(resource_id)
end

def home_page_title
  @home_page_title ||= begin
    home_html_erb = File.read("#{STASH_ENGINE_PATH}/app/views/stash_engine/pages/home.html.erb")
    home_html_erb[/page_title = '([^']+)'/, 1]
  end
end

# ------------------------------------------------------------
# Metadata helpers

def log_in!
  visit('/')
  first(:link_or_button, 'Login').click
end

def start_new_dataset!
  visit('/')
  first(:link_or_button, 'Login').click
  first(:link_or_button, 'Start New Dataset').click
  expect(page).to have_content('Describe Your Dataset')
end

def navigate_to_metadata!
  first(:link_or_button, 'Describe Dataset').click
  expect(page).to have_content('Describe Your Dataset')
end

def navigate_to_review!
  first(:link_or_button, 'Review and Submit').click
  expect(page).to have_content('Finalize Submission')
end

def fill_required_fields! # rubocop:disable Metrics/AbcSize
  # make sure we're on the right page
  expect(page).to have_content('Describe Your Dataset')

  # ##############################
  # Title

  title = find_blank_field_id('title')
  fill_in title, with: 'Of a peculiar Lead-Ore of Germany, and the Use thereof'

  # ##############################
  # Author

  author_first_name = find_blank_field_id('author[author_first_name]')
  fill_in author_first_name, with: 'Robert'
  author_last_name = find_blank_field_id('author[author_last_name]')
  fill_in author_last_name, with: 'Boyle'
  author_affiliation = find_blank_field_id('affiliation') # TODO: make consistent with other author fields
  fill_in author_affiliation, with: 'Hogwarts'
  author_email = find_blank_field_id('author[author_email]')
  fill_in author_email, with: 'boyle@hogwarts.edu'

  # TODO: additional author(s)

  # ##############################
  # Abstract

  abstract = find_blank_field_id('description_abstract')
  fill_in abstract, with: <<-ABSTRACT
        There was, not long since, sent hither out of Germany from
        an inquisitive Physician, a List of several Minerals and Earths
        of that Country, and of Hungary, together with a Specimen of each
        of them.
  ABSTRACT
end

def fill_in_future_pub_date(end_date)
  # make sure we're on the right page
  expect(page).to have_content('Finalize Submission')

  month_field = find_field_id('mmEmbargo')
  fill_in month_field, with: end_date.month

  day_field = find_field_id('ddEmbargo')
  fill_in day_field, with: end_date.day

  year_field = find_field_id('yyyyEmbargo')
  fill_in year_field, with: end_date.year
end
