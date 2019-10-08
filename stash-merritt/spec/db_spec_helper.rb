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

# rubocop:disable Lint/HandleExceptions
# had problems in tests with the columns being out of date, but only in a new database such as on Travis, ick. OUr nasty, janky test setup.
ActiveRecord::Base.descendants.each do |model|
  begin
    model.connection.schema_cache.clear!
    model.reset_column_information
  rescue NameError; end
end
# rubocop:enable Lint/HandleExceptions

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each) do
    # Mock all the mailers fired by callbacks because these tests don't load everything we need
    allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_author).and_return(true)
    allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations).and_return(true)
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Helpers

require 'util/resource_builder'
