# :nocov:
namespace :cleanup do

  # example usage: RAILS_ENV=development bundle exec rake cleanup:affiliations_wo_ror
  # https://github.com/datadryad/dryad-app/blob/main/documentation/technical_notes/affiliations.md#cleaning-affiliation-names
  desc 'Match Affiliations with ROR organizations'
  task affiliations_wo_ror: :environment do
    Stash::Organization::AffiliationRorMatcher.new(start_created_at: 2.months.ago).perform
  end

  # example usage: RAILS_ENV=development bundle exec rake cleanup:contributors_wo_ror
  # https://github.com/datadryad/dryad-app/blob/main/documentation/technical_notes/contributors.md#cleaning-contributor-names
  desc 'Match Contributors with ROR organizations'
  task contributors_wo_ror: :environment do
    Stash::Organization::ContributorRorMatcher.new(start_created_at: 2.months.ago).perform
  end
end
# :nocov:
