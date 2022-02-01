source 'https://rubygems.org'
require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

# ############################################################
# Rails

gem 'irb', '~> 1.3.7'
gem 'mysql2', '~> 0.5.3'
gem 'rails', '~> 5.2.6'
gem 'react-rails', '~> 2.6.1'
gem 'webpacker', '~> 5.4.0'

# ############################################################
# Local engines

path 'stash' do
  gem 'stash_datacite'
  gem 'stash_discovery'
  gem 'stash_engine'
  # needs engines to load first
  gem 'stash-merritt'
end

# ############################################################
# Deployment

gem 'capistrano', '~> 3.11'
gem 'capistrano-rails', '~> 1.4'
gem 'rubocop', '~> 0.90.0'
# Use Puma as the app server
gem 'puma', group: :puma, require: false
# Our homegrown artisinal SSM gem
gem 'uc3-ssm', git: 'https://github.com/CDLUC3/uc3-ssm', branch: '0.3.0rc0'

# ############################################################
# UI

# TODO: why do we have uglifier AND yui-compressor?
# asset pipeline problems with Joels pre-minified CSS/JS caused errors with uglifier and had to revert to yui-compressor

gem 'coffee-rails', '~> 4.1'
gem 'jquery-rails'
gem 'sass-rails', '~> 5.0'
gem 'libv8', '~> 3.16.14'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'
gem 'uglifier', '~> 4.2.0'
gem 'yui-compressor'

# ############################################################
# Misc
gem 'bootsnap', require: false
gem 'doorkeeper', '~> 5.5'
gem 'exception_notification'
gem 'google-apis-gmail_v1', '~> 0.3'
gem 'jbuilder'
gem 'net-sftp'
gem 'oai', '~> 1.1.0'
gem 'rack-attack'
gem 'rb-readline', require: false
gem 'wicked_pdf', '~> 1.4.0'
gem 'wkhtmltopdf-binary'

# #########################
# Testing download examples
gem 'down'
gem 'http'

# ############################################################
# Development and testing

group :development, :local_dev do
  gem 'colorize'
  gem 'web-console'
  # gem 'httplog', not needed always, but good for troubleshooting HTTP requests to outside http services from the app
end

group :test do
  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb (https://github.com/teamcapybara/capybara)
  gem 'capybara'
  # Automatically create snapshots when Cucumber steps fail with Capybara and Rails (http://github.com/mattheworiordan/capybara-screenshot)
  gem 'capybara-screenshot'
  # chromedriver-helper is now deprecated, use webdrivers instead
  gem 'webdrivers'
  # Strategies for cleaning databases.  Can be used to ensure a clean state for testing. (http://github.com/DatabaseCleaner/database_cleaner)
  gem 'database_cleaner', require: false
  # required for weird-ass rspec_custom_matchers that isn't in any actual gem/engine, but gets loaded in some weird circumstances
  gem 'diffy'
  # required for weird-ass rspec_custom_matchers that isn't in any actual gem/engine, but gets loaded in some weird circumstances
  gem 'equivalent-xml'
  # factory_bot_rails provides integration between factory_bot and rails 3 or newer (http://github.com/thoughtbot/factory_bot_rails)
  gem 'factory_bot_rails'
  # Easily generate fake data (https://github.com/stympy/faker)
  gem 'faker'
  # RSpec progress bar formatter (https://github.com/thekompanee/fuubar)
  gem 'fuubar'
  # Guard keeps an eye on your file modifications (http://guardgem.org)
  gem 'guard'
  # Guard gem for RSpec (https://github.com/guard/guard-rspec)
  gem 'guard-rspec'
  # Mocking and stubbing library (http://gofreerange.com/mocha/docs)
  gem 'mocha', require: false

  # RSpec for Rails (https://github.com/rspec/rspec-rails)
  gem 'rspec-collection_matchers'
  gem 'rspec-github', require: false
  gem 'rspec-rails'

  gem 'rspec-html'

  # The next generation developer focused tool for automated testing of webapps (https://github.com/SeleniumHQ/selenium)
  gem 'selenium-webdriver'
  # Making tests easy on the fingers and eyes (https://github.com/thoughtbot/shoulda)
  gem 'shoulda'
  # Simple one-liner tests for common Rails functionality (https://github.com/thoughtbot/shoulda-matchers)
  gem 'shoulda-matchers', '~> 4.0'
  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites (http://github.com/colszowka/simplecov)
  gem 'simplecov', require: false
  # used by some of the engines and for some reason causes errors without it in the main Gemfile, also.
  gem 'simplecov-console', require: false
  gem 'webmock'
end

group :development, :test, :local_dev do
  gem 'binding_of_caller'
  # Ruby fast debugger - base + CLI (http://github.com/deivid-rodriguez/byebug)
  gem 'byebug'
  gem 'listen'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote', require: 'pry-remote'
  # Rails application preloader (https://github.com/rails/spring), says not to install in production
  gem 'spring'
  # rspec command for spring (https://github.com/jonleighton/spring-commands-rspec)
  gem 'spring-commands-rspec'
end
