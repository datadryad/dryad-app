require 'spec_helper'
require 'database_cleaner'
require 'colorize'

# ------------------------------------------------------------
# ActiveRecord: database setup/teardown

# Always load the schema: https://relishapp.com/rspec/rspec-rails/docs/upgrade#pending-migration-checks
# TODO: do we need this if we're explicitly running migrations?
ActiveRecord::Migration.maintain_test_schema!

# Make sure we're not clobbering non-test data
def check_connection_config!
  db_config = ActiveRecord::Base.connection_config
  host = db_config[:host]
  raise("Can't run destructive tests against non-local database #{host || 'nil'}") unless host == 'localhost'
  msg = "Using database #{db_config[:database]} on host #{host} with username #{db_config[:username]}"
  puts msg.colorize(:yellow)
end

# Run migrations manually
def run_migrations!
  db_config = YAML.load_file('spec/config/database.yml')['test']
  ActiveRecord::Base.establish_connection(db_config)
  check_connection_config!

  migration_path = "#{ENGINE_PATH}/db/migrate"
  puts "Executing migrations from:\n\t#{migration_path}"
  ActiveRecord::Migration.verbose = true
  ActiveRecord::Migrator.up [migration_path]
end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.before(:suite) do
    run_migrations!

    # rubocop:disable Lint/HandleExceptions
    # had problems in tests with the columns being out of date, but only in a new database such as on Travis, ick. OUr nasty, janky test setup.
    ActiveRecord::Base.descendants.each do |model|
      begin
        model.connection.schema_cache.clear!
        model.reset_column_information
      rescue NameError; end
    end
    # rubocop:enable Lint/HandleExceptions

    DatabaseCleaner.strategy = :deletion
    puts 'Clearing test database'.colorize(:yellow)
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
