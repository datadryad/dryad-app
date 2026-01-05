source 'https://rubygems.org'
ruby '3.3.7'

# ############################################################
# Rails
gem 'irb', '~> 1.14.3'
gem 'mail', '~> 2.8'
gem 'mysql2', '~> 0.5.6'
gem 'rails', '~> 8.0.1'
gem 'react-rails', '~> 2.6.2'
gem 'shakapacker', '~> 6.0'
gem 'sprockets', '~> 4.0'

# ############################################################
# Deployment
gem 'bcrypt_pbkdf', '~> 1.0'
gem 'capistrano', '~> 3.17'
gem 'capistrano3-puma', github: 'seuros/capistrano-puma'
gem 'capistrano-rails', '~> 1.7.0'
gem 'capistrano-sidekiq', '~> 3.2.0'
gem 'capistrano-yarn'
gem 'ed25519', '>= 1.2', '< 2.0'
gem 'rdoc', '~> 6.1.1' # for some reason needs to be installed for capistrano to work right
gem 'rubocop', '~> 1.67.0', require: false
# Use Puma as the app server
gem 'puma', '6.6.0', group: :puma, require: false

# ############################################################
# UI
gem 'coffee-rails', '~> 5.0'
gem 'jquery-rails', '~> 4.6'
gem 'sassc-rails', '~> 2.1.2' # the default for newer rails
gem 'terser' # for JS and CSS minify

# ############################################################
# Misc
gem 'actionpack-page_caching'
gem 'acts_as_paranoid', '~> 0.10.3'
gem 'amatch', '~> 0.4.0'
gem 'amoeba', '~> 3.3.0'
gem 'aws-sdk-lambda'
gem 'aws-sdk-s3', '~> 1.208'
gem 'aws-sdk-sns'
gem 'bootsnap', require: false
gem 'charlock_holmes', '~> 0.7.9'
gem 'commonmarker', '~> 2.4'
gem 'concurrent-ruby', '~> 1.3.4'
gem 'daemons', '~> 1.4.1'
gem 'database_cleaner', '~> 2.0.1'
gem 'datacite-mapping', git: 'https://github.com/CDLUC3/datacite-mapping.git'
gem 'data_migrate'
gem 'doorkeeper', '~> 5.5'
gem 'down' # I'm not sure where this is used, but maybe in the frictionless data that Cassiano worked on to dl files
gem 'exception_notification', git: 'https://github.com/smartinez87/exception_notification.git'
gem 'ezid-client', '~> 1.9.2'
gem 'filesize', '~> 0.2.0'
gem 'font-awesome-sass', '~> 6.7.2'
gem 'google-apis-gmail_v1', '~> 0.14.0'
gem 'grover'
gem 'http', '~> 5.0.4'
gem 'httparty', '~> 0.24.0'
gem 'httpclient', '~> 2.8.3'
gem 'jbuilder' # is this used?
gem 'jquery-turbolinks', '~> 2.1.0'
gem 'jquery-ui-rails', '~> 7.0', git: 'https://github.com/jquery-ui-rails/jquery-ui-rails.git', tag: 'v7.0.0'
gem 'jwt', '~> 2.3.0'
gem 'kaminari', '~> 1.2.2'
gem 'leaflet-rails', '~> 1.7.0'
gem 'loofah', '~> 2.24.0'
gem 'net-ftp', '~> 0.3.4'
gem 'net-sftp'
gem 'noid', '~> 0.9.0'
gem 'omniauth', '~> 2.1.0'
gem 'omniauth-google-oauth2', '~> 1.1.1'
gem 'omniauth-orcid', '~> 2.1', '>= 2.1.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0.1'
gem 'omniauth-shibboleth', '~> 1.3.0'
gem 'paper_trail', '~> 16.0'
gem 'posix-spawn', '~> 0.3.15'
gem 'pundit', '~> 2.3'
gem 'rack-attack'
gem 'rb-readline', require: false
gem 'recaptcha', '~> 5.19'
gem 'redcarpet', '~> 3.6'
gem 'redis', '~> 5.4'
gem 'responders', '~> 3.0.1' # do we use this?
gem 'rest-client', '~> 2.1.0' # yet another http gem, not sure it's used
gem 'restforce', '~> 8.0.0'
gem 'rinku', '~> 2.0.6' # we used this one, creates links from text but not sure if we still use it
gem 'rsolr', '~> 2.6.0'
gem 'rubyzip', '~> 2.3', '>= 2.3.2'
gem 'serrano', '~> 1.6'
gem 'sidekiq', '~> 8.0.7'
gem 'sidekiq-unique-jobs', '~> 8.0.11'
gem 'stripe', '~> 5.50.0'
gem 'sync', '~> 0.5.0' # not sure where this is used
gem 'yaml', '~> 0.4.0' # version 0.2.0 breaks Gmail (https://github.com/datadryad/dryad-app/pull/771)
gem 'zaru', '~> 1.0.0' # for sanitizing file names

# Peer dependencies
# with future versions of activesupport and bootsnap, these may not be needed here

# gem 'base64'
# gem 'bigdecimal'
# gem 'mutex_m'
gem 'faraday', '~> 2.13'
gem 'faraday-retry'

# ############################################################
# Development and testing
group :test do
  # I'm not sure we're really using every one of these libraries like fuubar?, guard?, mocha?, rspec-html?, shoulda?
  # Capybara aims to simplify the process of integration testing Rack applications, such as Rails, Sinatra or Merb (https://github.com/teamcapybara/capybara)
  gem 'capybara'
  # Automatically create snapshots when Cucumber steps fail with Capybara and Rails (http://github.com/mattheworiordan/capybara-screenshot)
  gem 'capybara-screenshot'
  # required for weird-ass rspec_custom_matchers that isn't in any actual gem/engine, but gets loaded in some weird circumstances
  gem 'diffy' # used to define custom matchers in rspec_custom_matchers.rb
  # required for weird-ass rspec_custom_matchers that isn't in any actual gem/engine, but gets loaded in some weird circumstances
  gem 'equivalent-xml' # used to define custom matchers in rspec_custom_matchers.rb
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
  gem 'selenium-webdriver', '~> 4.11'
  # Making tests easy on the fingers and eyes (https://github.com/thoughtbot/shoulda)
  gem 'shoulda', '~> 4.0.0'
  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites (http://github.com/colszowka/simplecov)
  gem 'simplecov', require: false
  # used by some of the engines and for some reason causes errors without it in the main Gemfile, also.
  gem 'mock_redis', '~> 0.50.0'
  gem 'simplecov-console', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :development, :test, :dev do
  gem 'binding_of_caller'
  # Ruby fast debugger - base + CLI (http://github.com/deivid-rodriguez/byebug)
  gem 'byebug'
  gem 'drb'
  gem 'listen'
  gem 'pry'
  gem 'pry-rails'
  # Rails application preloader (https://github.com/rails/spring), says not to install in production
  gem 'spring'
  # rspec command for spring (https://github.com/jonleighton/spring-commands-rspec)
  gem 'letter_opener'
  gem 'letter_opener_web', '~> 3.0'
  gem 'spring-commands-rspec'
end

group :development, :dev do
  gem 'colorize'
  gem 'rack-mini-profiler'
  gem 'web-console'
end

group :development do
  gem 'annotaterb', '~> 4.13.0'
  gem 'bullet'
end
