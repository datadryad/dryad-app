require 'pp'
require_relative 'migration_import'
require 'database_cleaner'

# Tasks for migration of various content into the Dryad environment. Tasks in this file are not intended for
# long-term use; they are either for a single migration or for use over a limited time period.

namespace :dryad_migration do
  
  desc 'Migrate content from the v1 journal module'
  task migrate_journal_metadata: :environment do  
    i = 1
    File.foreach("journalISSNs.txt") do |issn|
      issn = issn.strip
      puts "#{i} #{issn}"
      i += 1
      url = APP_CONFIG.old_dryad_url + '/api/v1/journals/' + issn
      results = HTTParty.get(url,
                             query: { access_token: APP_CONFIG.old_dryad_access_token },
                             headers: { 'Content-Type' => 'application/json' })
      pr = results.parsed_response
      next if pr['fullName'].blank?
      puts pr['fullName']
    end
  end

  
  desc 'Test reading single item'
  task test: :environment do
    # see https://stackoverflow.com/questions/27913457/ruby-on-rails-specify-environment-in-rake-task
    # ActiveRecord::Base.establish_connection('test') # we only want to test against the local test db right now

    # DatabaseCleaner.strategy = :truncation
    # DatabaseCleaner.clean

    record_hash = JSON.parse(File.read(StashEngine::Engine.root.join('spec', 'data', 'migration_input.json')))

    id_importer = MigrationImport::Identifier.new(hash: record_hash)
    id_importer.import

    # my_id = StashEngine::Identifier.find(t)
    # hash = StashEngine::StashIdentifierSerializer.new(my_id).hash
    # pp(hash)

    # puts(hash.to_json)
  end

  desc 'Read in array of identifiers to db'
  task read_identifiers: :environment do
    # see https://stackoverflow.com/questions/27913457/ruby-on-rails-specify-environment-in-rake-task
    # TODO: get rid of this database cleaner when we run real migration
    # ActiveRecord::Base.establish_connection('test') # we only want to test against the local test db right now
    # DatabaseCleaner.strategy = :truncation
    # DatabaseCleaner.clean

    id_records = JSON.parse(File.read('/Users/sfisher/workspace/direct-to-old-dash2/dashv2/identifiers.json'))

    id_records.each_with_index do |id_record, counter|
      puts "#{counter + 1} of #{id_records.length}  #{id_record['identifier']}"
      id_importer = MigrationImport::Identifier.new(hash: id_record)
      id_importer.import
    end

  end

  desc 'Read in array of resources without identifiers to db'
  task read_resources: :environment do
    # see https://stackoverflow.com/questions/27913457/ruby-on-rails-specify-environment-in-rake-task
    # TODO: get rid of this database cleaner when we run real migration

    # ActiveRecord::Base.establish_connection('test') # we only want to test against the local test db right now
    # DatabaseCleaner.strategy = :truncation
    # DatabaseCleaner.clean

    resource_records = JSON.parse(File.read('/Users/sfisher/workspace/direct-to-old-dash2/dashv2/resources.json'))

    resource_records.each_with_index do |res_record, counter|
      puts "#{counter + 1} of #{resource_records.length}  #{res_record['title']}"
      res_importer = MigrationImport::Resource.new(hash: res_record, ar_identifier: nil)
      res_importer.import
    end

  end

end
