# :nocov:
namespace :cleanup do

  # example usage: RAILS_ENV=development bundle exec rake cleanup:affiliations_wo_ror
  # https://github.com/datadryad/dryad-app/blob/main/documentation/technical_notes/affiliations.md#cleaning-affiliation-names
  desc 'Match Affiliations with ROR organizations'
  task affiliations_wo_ror: :environment do
    Stash::Organization::AffiliationRorMatcher.new(start_created_at: 2.months.ago).perform
  end

  # example usage: RAILS_ENV=development bundle exec rake cleanup:duplicate_affiliations
  task duplicate_affiliations: :environment do
    Stash::Organization::AffiliationCleaner.perform
  end

  # example usage: RAILS_ENV=development bundle exec rake cleanup:contributors_wo_ror
  # https://github.com/datadryad/dryad-app/blob/main/documentation/technical_notes/contributors.md#cleaning-contributor-names
  desc 'Match Contributors with ROR organizations'
  task contributors_wo_ror: :environment do
    Stash::Organization::ContributorRorMatcher.new(start_created_at: 2.months.ago).perform
  end

  desc 'Delete orphan records'
  task delete_orphan_records: :environment do
    puts ''
    puts "Delete orphan records #{Time.current}:"
    curation_activities = StashEngine::CurationActivity.left_joins(:resource).where(stash_engine_resources: { id: nil })
    puts "Deleting CurationActivity with IDs: #{curation_activities.ids}"
    curation_activities.destroy_all

    versions = StashEngine::Version.left_joins(:resource).where(stash_engine_resources: { id: nil })
    puts "Deleting Version with IDs: #{versions.ids}"
    versions.destroy_all
  end

  task delete_copied_frictionless_reports: :environment do
    puts ''
    puts "Delete copied frictionless reports #{Time.current}:"
    reports = StashEngine::FrictionlessReport.joins(:generic_file).where(stash_engine_generic_files: { file_state: %w[copied deleted] })

    puts "Deleting #{reports.count} frictionless reports"
    reports.destroy_all

    puts 'Done'
  end
end
# :nocov:
