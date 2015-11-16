source 'https://rubygems.org'
require File.join(File.dirname(__FILE__), 'lib', 'bundler_help.rb')

ruby "2.2.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'
# Use mysql as the database for Active Record
#gem 'mysql2'
gem 'mysql2', '~> 0.3.18'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
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
gem 'capistrano', '~> 3.1'
gem 'capistrano-rails', '~> 1.1'
gem 'capistrano-passenger'
gem 'passenger'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  #testing framework
  gem 'rspec-rails', '~> 3.0'

  #test coverage
  #gem 'simplecov' # TODO do we care about the version?
  #gem 'simplecov-console' # TODO do we care about the version?

end

# set LOCAL_ENGINES=true (LOCAL_ENGINES=true rails s) to use local
#
# I had very frustating problems where it wouldn't read changes in the environment variable in rails
# console and got rid of it with "spring stop" before rails c would read new env variables.
# Spring is a preloader that runs in the background all the time for faster startup.
# https://github.com/rails/rails/issues/19256
# Do 'export DISABLE_SPRING=1' in your .bash_profile to keep it from running and messing you up
# if you are switching back and forth for debugging often.

if BundlerHelp.find_path('stash_engine') && ENV.to_hash['LOCAL_ENGINES'] == 'true'
  gem 'stash_engine', :path => BundlerHelp.find_path('stash_engine')
else
  gem 'stash_engine', :git => 'https://github.com/CDLUC3/stash_engine.git', :branch => 'development'
end

if BundlerHelp.find_path('stash_datacite') && ENV.to_hash['LOCAL_ENGINES'] == 'true'
  gem 'stash_datacite', :path => BundlerHelp.find_path('stash_datacite')
else
  gem 'stash_datacite', :git => 'https://github.com/CDLUC3/stash_datacite.git', :branch => 'development'
end

#gem "omniauth-shibboleth", :git => "https://bitbucket.org/cdl/omniauth-shibboleth.git", :branch => 'master'


