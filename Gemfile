source 'https://rubygems.org'
# do we need this still?
# require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

# ############################################################
# Rails

gem 'irb', '~> 1.4.1'
gem 'mysql2', '~> 0.5.3'
gem 'rails', '~> 5.2.7'
gem 'react-rails', '~> 2.6.2'
gem 'webpacker', '~> 5.4.3'

# ############################################################
# Local engines

path 'stash' do
  gem 'stash-merritt'
  gem 'stash-sword'
  gem 'stash-wrapper'
end

# ############################################################
# Deployment

gem 'capistrano', '~> 3.17'
gem 'capistrano-rails', '~> 1.6.2'
gem 'rubocop', '~> 0.90.0'
# Use Puma as the app server
gem 'puma', group: :puma, require: false
# Our homegrown artisinal SSM gem
gem 'uc3-ssm', git: 'https://github.com/CDLUC3/uc3-ssm', branch: '0.3.0rc0'

# ############################################################
# UI

# TODO: why do we have uglifier AND yui-compressor?
# asset pipeline problems with Joels pre-minified CSS/JS caused errors with uglifier and had to revert to yui-compressor

gem 'coffee-rails', '~> 5.0'
gem 'jquery-rails', '~> 4.4.0'
# gem 'libv8', '~> 3.16.1' # I think taken care of as dependency of mini_racer
gem 'sass-rails', '~> 5.0'
gem 'mini_racer'
# gem 'therubyracer', platforms: :ruby # this is very outdated and people say to use mini_racer instead if possible
gem 'turbolinks'
gem 'uglifier', '~> 4.2.0'
# gem 'yui-compressor' # I think no longer used

# ############################################################
# Misc

gem 'amatch', '~> 0.4.0'
gem 'amoeba', '~> 3.2.0'
gem 'aws-sdk-s3', '~> 1.111'
gem 'blacklight', '~> 7.19.2'
gem 'bootsnap', require: false
gem 'bootstrap', '~> 4.0'
gem 'concurrent-ruby', '~> 1.1.9'
gem 'daemons', '~> 1.4.1'
gem 'database_cleaner', '~> 2.0.1'
gem 'datacite-mapping', '~> 0.4.1'
gem 'delayed_job_active_record', '~> 4.1.6'
gem 'devise', '~> 4.8.0'
gem 'devise-guests', '~> 0.6'
gem 'doorkeeper', '~> 5.5'
gem 'down'
gem 'exception_notification'
gem 'ezid-client', '~> 1.9.1'
gem 'filesize', '~> 0.2.0'
gem 'font-awesome-rails', '~> 4.7.0.7'
gem 'geoblacklight', '~> 3.4.0'
gem 'google-apis-gmail_v1', '~> 0.3'
gem 'http', '~> 5.0.2'
gem 'httparty', '~> 0.19.0'
gem 'httpclient', '~> 2.8.3'
gem 'jbuilder'
gem 'jquery-turbolinks', '~> 2.1.0'
gem 'jquery-ui-rails', '~> 6.0.1'
gem 'jwt', '~> 2.2.3'
gem 'kaminari', '~> 1.2.1'
gem 'leaflet-rails', '~> 1.7.0'
gem 'loofah', '~> 2.12.0'
gem 'net-sftp'
gem 'noid', '~> 0.9.0'
gem 'oai', '~> 1.1.0'
gem 'omniauth', '~> 1.8', '>= 1.8.1'
gem 'omniauth-orcid', '~> 2.1', '>= 2.1.1'
gem 'omniauth-rails_csrf_protection', '~> 0.1', '>= 0.1.2'
gem 'omniauth-shibboleth', '~> 1.2', '>= 1.2.1'
gem 'posix-spawn', '~> 0.3.15'
gem 'rack-attack'
gem 'rb-readline', require: false
gem 'redcarpet', '~> 3.5.1'
gem 'responders', '~> 3.0.1'
gem 'rest-client', '~> 2.1.0'
gem 'restforce', '~>5.1.0'
gem 'rinku', '~> 2.0.6'
gem 'rsolr', '~> 2.3.0'
gem 'rubyzip', '~> 2.3', '>= 2.3.2'
gem 'serrano', '~> 1.0.0'
gem 'solr_wrapper', '~> 3.1.2'
gem 'stripe', '~> 5.38.0'
gem 'sync', '~> 0.5.0'
gem 'tins', '~> 1.29.1'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript' # this is in a generator to install blacklight
gem 'wicked_pdf', '~> 1.4.0'
gem 'wkhtmltopdf-binary'
gem 'yaml', '~> 0.1.1' # version 0.2 breaks Gmail, see https://github.com/CDL-Dryad/dryad-app/pull/771
gem 'zaru', '~> 0.3.0' # for sanitizing file names

# ############################################################
# Development and testing

gem 'parallel_tests', group: %i[development test]

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
