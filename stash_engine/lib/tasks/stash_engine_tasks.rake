require_relative 'identifier_rake_functions'

namespace :identifiers do
  desc 'Give resources missing a stash_engine_identifier one (run from main app, not engine)'
  task fix_missing: :environment do # loads rails environment
    IdentifierRakeFunctions.update_identifiers
  end

  desc "Update identifiers latest resource if they don't have one"
  task add_latest_resource: :environment do
    StashEngine::Identifier.where(latest_resource_id: nil).each do |se_identifier|
      puts "Updating identifier #{se_identifier.id}: #{se_identifier}"
      res = StashEngine::Resource.where(identifier_id: se_identifier.id).order(created_at: :desc).first
      if res.nil?
        se_identifier.destroy! # useless orphan identifier with no contents which should be deleted
      else
        se_identifier.update!(latest_resource_id: res.id)
      end
    end
  end

  desc 'Add searchable field contents for any identifiers missing it'
  task add_search: :environment do
    StashEngine::Identifier.where(search_words: nil).each do |se_identifier|
      puts "Updating identifier #{se_identifier} for search"
      se_identifier.update_search_words!
    end
  end
end
