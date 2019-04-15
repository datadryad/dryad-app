require 'httparty'

require_relative 'identifier_rake_functions'

# rubocop:disable Metrics/BlockLength
namespace :organizations do

  desc 'Rebuild the stash_engine_organizations table'
  task rebuild: :environment do
    Rake::Task['organizations:clear'].execute
    Rake::Task['organizations:retrieve_from_ror'].execute
  end

  desc 'Delete all records from the stash_engine_organizations table'
  task clear: :environment do
    StashEngine::Organization.destroy_all
  end

  desc 'Retrieve the latest list of organizations from ROR and add to the stash_engine_organizations table'
  task retrieve_from_ror: :environment do # loads rails environment
    uri = 'https://api.ror.org/organizations'
    results = HTTParty.get(uri, headers: { 'Content-Type': 'application/json' })
    errored = results.code < 200 || (results.code > 299 && results.code != 404)
    log.error("Unable to connect to ROR #{uri}: status: #{results.code}") if errored
    log.error('No organizations returned from ROR') if results.parsed_response.blank? || results.parsed_response['items'].blank?

    results.parsed_response['items'].each do |item|
      next unless item['id'].present?
      org = StashEngine::Organization.find_or_create_by(identifier: item['id'])
      org.update(
        name: item['name'],
        country: item['country'].present? ? item['country']['country_name'] : nil,
        acronyms: item['acronyms'],
        aliases: item['aliases']
      )
    end
  end

end
# rubocop:enable Metrics/BlockLength
