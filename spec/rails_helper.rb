require 'spec_helper'

if (env = ENV['RAILS_ENV'])
  raise "Can't run tests in environment #{env}" if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'database_cleaner'

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.strategy = :deletion }
  config.after(:each) { DatabaseCleaner.clean }
end
