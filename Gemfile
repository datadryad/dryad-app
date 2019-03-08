source 'https://rubygems.org'
require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

# ############################################################
# Rails

gem 'mysql2', '~> 0.4.10'
gem 'rails', '4.2.11'

# ############################################################
# Local engines

path '../stash' do
  gem 'stash_api'
  gem 'stash_datacite'
  gem 'stash_discovery'
  gem 'stash_engine'
  # needs engines to load first
  gem 'stash-merritt'
end

# ############################################################
# Deployment

gem 'capistrano', '~> 3.4.1'
gem 'capistrano-passenger'
gem 'capistrano-rails', '~> 1.1'
gem 'passenger'
gem 'rubocop', '~> 0.52.1'

# ############################################################
# UI

# TODO: why do we have uglifier AND yui-compressor?
# asset pipeline problems with Joel's pre-minified CSS/JS caused errors with uglifier and had to revert to yui-compressor

gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'sass-rails', '~> 5.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'

gem 'uglifier', '~> 3.0.4'
gem 'yui-compressor'

# ############################################################
# Misc

gem 'exception_notification'
gem 'httparty'
gem 'jbuilder', '~> 2.0'
gem 'stripe'

# ############################################################
# Development and testing

group :development do
  gem 'colorize', '~> 0.8'
  gem 'web-console', '~> 2.0'
end

group :test do
  # RSpec for Rails (https://github.com/rspec/rspec-rails)
  gem 'rspec-rails', '~> 3.0'
  gem "rspec-collection_matchers"
  # Guard keeps an eye on your file modifications (http://guardgem.org)
  gem "guard"
  # Guard gem for RSpec (https://github.com/guard/guard-rspec)
  gem "guard-rspec"

  # Rails application preloader (https://github.com/rails/spring)
  gem "spring"
  # rspec command for spring (https://github.com/jonleighton/spring-commands-rspec)
  gem "spring-commands-rspec"

  # Strategies for cleaning databases.  Can be used to ensure a clean state for testing. (http://github.com/DatabaseCleaner/database_cleaner)
  gem 'database_cleaner', require: false
  # factory_bot_rails provides integration between factory_bot and rails 3 or newer (http://github.com/thoughtbot/factory_bot_rails)
  gem 'factory_bot_rails'
  # Ruby fast debugger - base + CLI (http://github.com/deivid-rodriguez/byebug)
  gem 'byebug'

  # Easily generate fake data (https://github.com/stympy/faker)
  gem 'faker'
  # RSpec progress bar formatter (https://github.com/thekompanee/fuubar)
  gem 'fuubar'
  # Library for stubbing HTTP requests in Ruby. (http://github.com/bblimke/webmock)
  gem 'webmock'
  # Mocking and stubbing library (http://gofreerange.com/mocha/docs)
  gem "mocha", require: false
  # Making tests easy on the fingers and eyes (https://github.com/thoughtbot/shoulda)
  gem 'shoulda'

  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb (https://github.com/teamcapybara/capybara)
  gem 'capybara'
  # Automatically create snapshots when Cucumber steps fail with Capybara and Rails (http://github.com/mattheworiordan/capybara-screenshot)
  gem 'capybara-screenshot'
  # The next generation developer focused tool for automated testing of webapps (https://github.com/SeleniumHQ/selenium)
  gem 'selenium-webdriver', '~> 3.14'
  # Easy installation and use of chromedriver. (https://github.com/flavorjones/chromedriver-helper)
  gem 'chromedriver-helper', '>= 1.2'

  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites (http://github.com/colszowka/simplecov)
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'binding_of_caller'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
end
