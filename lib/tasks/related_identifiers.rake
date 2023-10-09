# :nocov:
require_relative 'related_identifiers/replacements'
require 'csv'

namespace :related_identifiers do

  desc 'update all the DOIs I can into correct format (in separate field)'
  task fix_common_doi_problems: :environment do
    Tasks::RelatedIdentifiers::Replacements.update_doi_prefix
    Tasks::RelatedIdentifiers::Replacements.update_bare_doi
    Tasks::RelatedIdentifiers::Replacements.move_good_format
    Tasks::RelatedIdentifiers::Replacements.update_http_good
    Tasks::RelatedIdentifiers::Replacements.update_http_dx_doi
    Tasks::RelatedIdentifiers::Replacements.update_protocol_free
    Tasks::RelatedIdentifiers::Replacements.update_non_ascii
    Tasks::RelatedIdentifiers::Replacements.remaining_strings_containing_dois
  end

  # not sure we'll ever see this format again, a one-off spreadsheet from Ted
  desc 'An ephemeral csv from Ted with our doi, preprint doi and primary article doi'
  task ted_preprint_csv: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end

    unless ARGV.length == 2
      puts 'Please put the path to the file to process'
      next
    end
    rows = CSV.read(ARGV[1])

    rows.each do |row|
      stash_id = StashEngine::Identifier.where(identifier: row[0]).first
      res = stash_id.latest_resource

      StashDatacite::RelatedIdentifier.upsert_simple_relation(doi: row[1], resource_id: res.id, work_type: 'preprint')
      StashDatacite::RelatedIdentifier.upsert_simple_relation(doi: row[2], resource_id: res.id, work_type: 'primary_article')
    end
    puts 'done'
  end
end
# :nocov:
