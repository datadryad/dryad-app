require 'spec_helper'

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'database_cleaner'

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # allow test DB access from multiple connections
  config.use_transactional_fixtures = false

  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  config.before(:suite) { DatabaseCleaner.strategy = :deletion }
  config.after(:each) { DatabaseCleaner.clean }
end
