# frozen_string_literal: true

require_relative 'solr'
require_relative 'helpers/ajax_helper'
require_relative 'helpers/capybara_helper'
require_relative 'helpers/ckeditor_helper'
require_relative 'helpers/routes_helper'
require_relative 'helpers/session_helper'
require_relative 'helpers/webmock_helper'

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :chrome

# This is a customisation of the default :selenium_chrome_headless config in:
# https://github.com/teamcapybara/capybara/blob/master/lib/capybara.rb
#
# This adds the --no-sandbox flag to fix TravisCI as described here:
# https://docs.travis-ci.com/user/chrome#sandboxing
Capybara.register_driver :selenium_chrome_headless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--no-sandbox'
  browser_options.args << '--window-size=1280,1024'
  browser_options.args << '--disable-gpu' if Gem.win_platform?
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

RSpec.configure do |config|

  config.before(:each, type: :feature, js: false) do
    Capybara.use_default_driver
  end

  config.before(:each, type: :feature, js: true) do
    Capybara.current_driver = :selenium_chrome_headless
  end

end

Capybara.configure do |config|
  config.default_max_wait_time = 5 # seconds
  config.server                = :webrick
  config.raise_server_errors   = true
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

RSpec.configure do |config|
  # config.include(AjaxHelper, type: :feature)
  config.include(CapybaraHelper, type: :feature)

  config.before(:all, type: :feature) do
    config.include(CkeditorHelper, type: :feature)
    config.include(RoutesHelper, type: :feature)
    config.include(SessionsHelper, type: :feature)
    config.include(WebmockHelper, type: :feature)

    disable_net_connect!
  end
end
