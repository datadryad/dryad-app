# :nocov:
namespace :recurate do

  # example usage: RAILS_ENV=development bundle exec rake recurate:nih_contributors
  desc 'Re-curate contributors that have NIH as direct funder'
  task nih_contributors: :environment do
    StashDatacite::Contributor.where(name_identifier_id: NIH_ROR).each do |contrib|
      AwardMetadataService.new(contrib).populate_from_api
    end
  end

  # example usage: RAILS_ENV=development bundle exec rake recurate:populate_missing_awards
  desc 'Re-curate contributors that have an award number, but award title is missing'
  task populate_missing_awards: :environment do
    StashDatacite::Contributor.needs_award_details.each do |contrib|
      AwardMetadataService.new(contrib).populate_from_api
    end
  end

  # example usage: RAILS_ENV=development bundle exec rake recurate:populate_descriptions_awards
  desc 'Re-curate resources that have award number in descriptions(abstract or methods) matching NIH format'
  task populate_descriptions_awards: :environment do
    descriptions = StashDatacite::Description.where("description LIKE '%0%'")
    descriptions.each do |description|
      description.description.scan(NIH_GRANT_REGEX) do |grant|
        next if grant.blank?

        resource = description.resource
        next if resource.funders.where("award_number like '%#{grant}%'").exists?

        # create a new NIH funder based on award number found in description
        # and populate data
        contributor = Contributors::CreateService.new(resource).create(
          { contributor_type: 'funder', award_number: grant, identifier_type: 'ror', name_identifier_id: NIH_ROR }
        )
        AwardMetadataService.new(contributor).populate_from_api

        # delete the default funder created from UI
        if !contributor.new_record? && resource.funders.count == 2 && resource.funders.where(name_identifier_id: '0').exists?
          resource.funders.where(name_identifier_id: '0').destroy_all
        end
      end
    end
  end

  # example usage: RAILS_ENV=development bundle exec rake recurate:fetch_awards_from_pubmed
  # rubocop:disable Layout/LineLength
  desc 'Re-curate resources that have no award number by matching data from PubMed'
  task fetch_awards_from_pubmed: :environment do
    StashEngine::Resource.latest_per_dataset.left_joins(:funders)
      .group('stash_engine_resources.id')
      .having("COUNT(dcs_contributors.id) = 0 OR SUM(CASE WHEN dcs_contributors.award_number IS NOT NULL AND dcs_contributors.award_number <> '' THEN 1 ELSE 0 END) = 0")
      .each do |resource|

      Contributors::CreateService.new(resource).create_funder_from_pubmed(NIH_ROR)
    end
  end
  # rubocop:enable Layout/LineLength

  # example usage: RAILS_ENV=development bundle exec rake recurate:sri_lanka_remapping
  desc 'Re-curate resources that have no award number by matching data from PubMed'
  task sri_lanka_remapping: :environment do
    res = []
    ror_id = 'https://ror.org/010xaa060'
    StashDatacite::Contributor.funder.rors.where(name_identifier_id: ror_id).each do |contrib|
      # for already updated awards, skip
      next if contrib.name_identifier_id != ror_id

      res << Contributors::UpdateByAwardService.new(contrib).call
    end

    CSV.open(File.join(REPORTS_DIR, "sri_lanka_remapping_#{Date.today}.csv"), 'w') do |csv|
      csv << ['Status', 'ID', 'Identifier', 'Identifier ID', 'Resource ID', 'Award Number', 'Old Award Number']
      res.each do |row|
        csv << [
          row[:status],
          row[:contributor_id],
          row[:identifier],
          row[:identifier_id],
          row[:resource_id],
          row[:award_number],
          row[:initial_award_number]
        ]
      end
    end
  end

  # example usage: RAILS_ENV=development bundle exec rake recurate:pakistan_remapping
  desc 'Re-curate resources that have no award number by matching data from PubMed'
  task pakistan_remapping: :environment do
    res = []
    ror_id = 'https://ror.org/05h1kgg64'
    StashDatacite::Contributor.funder.rors.where(name_identifier_id: ror_id).each do |contrib|
      # for already updated awards, skip
      next if contrib.name_identifier_id != ror_id

      res << Contributors::UpdateByAwardService.new(contrib).call
    end

    CSV.open(File.join(REPORTS_DIR, "pakistan_remapping_#{Date.today}.csv"), 'w') do |csv|
      csv << ['Status', 'ID', 'Identifier', 'Identifier ID', 'Resource ID', 'Award Number', 'Old Award Number']
      res.each do |row|
        csv << [
          row[:status],
          row[:contributor_id],
          row[:identifier],
          row[:identifier_id],
          row[:resource_id],
          row[:award_number],
          row[:initial_award_number]
        ]
      end
    end
  end
end
# :nocov:
