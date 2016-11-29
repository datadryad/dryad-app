require 'spec_helper'
require 'database_cleaner'

db_config = YAML.load_file('config/database.yml')['test']

host = db_config['host']
raise("Can't run destructive tests against non-local database #{host}") unless host == 'localhost'
puts "Using database #{db_config['database']} on host #{db_config['host']} with username #{db_config['username']}"

stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
migration_paths = ["#{stash_engine_path}/db/migrate"]

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Migration.verbose = true
puts "Executing migrations from #{migration_paths.join(':')}"
ActiveRecord::Migrator.up migration_paths

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
