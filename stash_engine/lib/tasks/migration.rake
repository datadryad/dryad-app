require 'pp'
require 'byebug'
require_relative 'migration_importer'
require 'database_cleaner'
namespace :dryad_migration do

  desc 'Test reading single item'
  task test: :environment do
    # see https://stackoverflow.com/questions/27913457/ruby-on-rails-specify-environment-in-rake-task
    ActiveRecord::Base.establish_connection('test') # we only want to test against the local test db right now

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean


    record_hash = JSON.parse(File.read(StashEngine::Engine.root.join('spec', 'data', 'migration_input.json')))

    # migration_importer = MigrationImporter.new(record_hash)


    # my_id = StashEngine::Identifier.find(t)
    # hash = StashEngine::StashIdentifierSerializer.new(my_id).hash
    # pp(hash)

    # puts(hash.to_json)
  end
end