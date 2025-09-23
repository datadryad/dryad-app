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

      # check for pubmed_id
      pubmed_records = resource.identifier.internal_data.where(data_type: 'pubmedID')
      if pubmed_records.any?
        pubmed_records .each do |pubmed|
          Contributors::CreateService.new(resource).create_funder_from_pubmed(pubmed.value, NIH_ROR)
        end
        next
      end

      # check for primary_article
      articles = resource.related_identifiers.primary_article.where(related_identifier_type: 'doi')
      next unless articles.any?

      articles.each do |article|
        doi = Stash::Import::Crossref.bare_doi(doi_string: article.related_identifier)
        pmid = Integrations::PubMed.new.pmid_by_primary_article(doi)
        next if pmid.blank?

        # add PubMed ID to the database
        resource.identifier.internal_data.where(data_type: 'pubmedID').find_or_create_by(value: pmid)
        Contributors::CreateService.new(resource).create_funder_from_pubmed(pmid, NIH_ROR)
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
# :nocov:
