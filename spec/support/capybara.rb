# frozen_string_literal: true

require_relative 'solr'
require_relative 'helpers/page_load_helper'
require_relative 'helpers/capybara_helper'
require_relative 'helpers/routes_helper'
require_relative 'helpers/session_helper'
require_relative 'helpers/webmock_helper'
# require 'webdrivers'

# Webdrivers::Chromedriver.update

# make CAPY_SHOW environment variable set to see the browser doing its thing
if ENV['CAPY_SHOW']
  Capybara.default_driver = :selenium_chrome
  Capybara.javascript_driver = :selenium_chrome
else
  Capybara.default_driver = :rack_test
  Capybara.javascript_driver = :selenium_chrome_headless
end

# uncomment following lines to see actions in browser

# TODO: is it necessary :chrome if we already run with :selenium_chrome
# Capybara.javascript_driver = :chrome

# change all :selenium_chrome_headless to just :selenium_chrome in this file in order to see your tests and troubleshoot in browser.
# also, comment out --headless option.  Also change default_driver from :rack_test to :selenium_chrome
Capybara.asset_host = 'http://localhost:33000'
Capybara.enable_aria_label = true

# disable css transitions
Capybara.disable_animation = true

# Webdrivers.install_dir = '~/.webdrivers'
# Selenium::WebDriver::Chrome.path = '~/.webdrivers/chromedriver'

# This is a customisation of the default :selenium_chrome_headless config in:
# https://github.com/teamcapybara/capybara/blob/master/lib/capybara.rb
#
# This adds the --no-sandbox flag to fix TravisCI as described here:
# https://docs.travis-ci.com/user/chrome#sandboxing
#
# This stupid capybara driver started breaking again and not setting chrome options correctly, so
# based this on https://gist.github.com/mars/6957187 and it seemed to fix my problems.

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless=new')
  options.add_argument('--window-size=1920,1080')

  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')

  options.add_argument('--disable-gpu')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-popup-blocking')

  options.add_argument('--disable-search-engine-choice-screen')

  options.add_argument(
    '--disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationTargetPrediction,OptimizationHints'
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

RSpec.configure do |config|
  config.before(:each, type: :feature, js: false) do
    Capybara.use_default_driver
  end
end

Capybara.configure do |config|
  config.default_max_wait_time = 5 # used to be 5 or 15 seconds until travis started acting up
  config.server                = :puma # used to be webrick
  config.raise_server_errors   = true
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

RSpec.configure do |config|
  config.include(PageLoadHelper, type: :feature)
  config.include(CapybaraHelper, type: :feature)

  config.before(:all, type: :feature) do
    config.include(RoutesHelper, type: :feature)
    config.include(SessionsHelper, type: :feature)
    config.include(WebmockHelper, type: :feature)

    disable_net_connect!
  end
end
