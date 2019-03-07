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
  gem 'webmock'
  gem 'database_cleaner', require: false
  gem 'shoulda'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver', '~> 3.14'
  gem 'chromedriver-helper', '>= 1.2'
end

group :development, :test do
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'rspec-rails', '~> 3.0'
end
