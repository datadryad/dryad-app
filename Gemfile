source 'https://rubygems.org'
require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

# ############################################################
# Rails

gem 'rails', '4.2.7.1'
gem 'mysql2', '~> 0.3.18'

# ############################################################
# Local engines

path '../stash' do
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

# ############################################################
# UI

# TODO: why do we have uglifier AND yui-compressor?

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
gem 'jbuilder', '~> 2.0'
gem 'httparty'

# ############################################################
# Development and testing

group :development do
  gem 'web-console', '~> 2.0'
end

group :test do
  gem 'capybara', '~> 2.14'
  gem 'chromedriver-helper', '~> 1.1'
  gem 'rubocop', '~> 0.49'
  gem 'selenium-webdriver', '~> 3.4'
  gem 'simplecov', '~> 0.9.2'
  gem 'simplecov-console', '~> 0.2.0'
end

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'spring'
end

