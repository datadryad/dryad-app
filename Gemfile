source 'https://rubygems.org'
require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

ruby '2.2.5'

gem 'yui-compressor'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use mysql as the database for Active Record
# gem 'mysql2'
gem 'mysql2', '~> 0.3.18'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 3.0.4'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
gem 'capistrano', '~> 3.4.1'
gem 'capistrano-passenger'
gem 'capistrano-rails', '~> 1.1'
gem 'httparty'
gem 'passenger'
gem 'rubocop'

# run DelayedJob jobs in the background
gem 'daemons'

gem 'exception_notification'

group :development do
  gem 'web-console', '~> 2.0'
end

group :test do
  gem 'simplecov', '~> 0.9.2'
  gem 'simplecov-console', '~> 0.2.0'
end

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'spring'
end

path '../stash' do
  gem 'stash_datacite'
  gem 'stash_discovery'
  gem 'stash_engine'
  # needs engines to load first
  gem 'stash-merritt'
end
