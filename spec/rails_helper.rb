require 'spec_helper'
require 'colorize'
require 'byebug'

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end

puts("THE FILE: #{__FILE__}")
puts("THE FILE PATH: #{File.expand_path('../../config/environment', __FILE__)}")

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'database_cleaner'

ActiveRecord::Migration.maintain_test_schema!

def check_connection_config!
  db_config = ActiveRecord::Base.connection_config
  host = db_config[:host]
  raise("Can't run destructive tests against non-local database #{host || 'nil'}") unless host == 'localhost'
  msg = "Using database #{db_config[:database]} on host #{host} with username #{db_config[:username]}"
  puts msg.colorize(:yellow)
end

RSpec.configure do |config|
  # allow test DB access from multiple connections
  config.use_transactional_fixtures = false

  config.fixture_path = "#{Rails.root}/spec/fixtures"

  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion

    check_connection_config!

    puts 'Clearing test database'.colorize(:yellow)
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
