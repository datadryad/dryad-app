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
    StashDatacite::Contributor.where.not(award_number: [nil, ''])
      .where(award_title: [nil, ''])
      .each do |contrib|

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
        contributor = resource.funders.create(award_number: grant, identifier_type: 'ror', name_identifier_id: NIH_ROR)
        AwardMetadataService.new(contributor).populate_from_api

        # delete the default funder created from UI
        if !contributor.new_record? && resource.funders.count == 2 && resource.funders.where(name_identifier_id: '0').exists?
          resource.funders.where(name_identifier_id: '0').destroy_all
        end
      end
    end
  end
end
# :nocov:
