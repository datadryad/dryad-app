require 'yaml'
require 'database_cleaner'
require 'spec_helper'

db_config = YAML.load_file('spec/config/database.yml')['test']

host = db_config['host']
raise("Can't run destructive tests against non-local database #{host}") unless host == 'localhost'
puts "Using database #{db_config['database']} on host #{db_config['host']} with username #{db_config['username']}"

stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
stash_datacite_path = Gem::Specification.find_by_name('stash_datacite').gem_dir
migration_paths = %W[#{stash_engine_path}/db/migrate #{stash_datacite_path}/db/migrate]

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Migration.verbose = false
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

# Helpers

require 'util/resource_builder'
