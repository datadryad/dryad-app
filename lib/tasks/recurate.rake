# :nocov:
namespace :recurate do

  # example usage: RAILS_ENV=development bundle exec rake recurate:nih_contributors
  # https://github.com/datadryad/dryad-app/blob/main/documentation/technical_notes/affiliations.md#cleaning-affiliation-names
  desc 'Match Affiliations with ROR organizations'
  task nih_contributors: :environment do
    StashDatacite::Contributor.where(name_identifier_id: NIH_ROR).each do |contrib|
      AwardMetadataService.new(contrib).populate_from_api
    end
  end
end
# :nocov:
