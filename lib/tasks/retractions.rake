# :nocov:
namespace :retractions do

  desc 'Check Crossref for retractions by date'
  task date_updates: :environment do
    # Run weekly. Gets retractions since last run and checks for Dryad matches
    from_date = Rails.cache.read('retraction-search-date') || 1.week.ago.strftime('%F')
    p "Checking Crossref API for retractions since #{from_date}"
    results = Integrations::Crossref.query_updates(from_date: from_date)
    results.each do |result|
      update = result['update-to'].find { |u| u['type'] == 'retraction' }
      next unless update&.[]('DOI')&.present?

      ri = StashDatacite::RelatedIdentifier.where(work_type: 'primary_article').where("related_identifier like '%#{update['DOI']}'")
      next unless ri.present? && ri.resource.present?

      p "  found retraction for: #{ri.resource.identifier.identifier}"
      Stash::Import::Crossref.new(resource: ri.resource, json: update).to_retraction_note
    end

    Rails.cache.write('retraction-search-date', Date.today.strftime('%F'))
  end

  desc 'Check Crossref for retraction updates to Dryad primary articles'
  task article_updates: :environment do
    # Run rarely. Searches Crossref for all Dryad published primary articles and records retractions.

    articles = StashEngine::Resource.latest_per_dataset
      .joins("join dcs_related_identifiers pa on pa.resource_id = stash_engine_resources.id and pa.work_type = 6 and related_identifier_type = 'doi'")
      .joins(
        "left outer join dcs_descriptions d on d.resource_id = stash_engine_resources.id
        and d.description_type = 'concern' and d.description is not null and d.description != ''"
      )
      .where("d.id is null and stash_engine_identifiers.pub_state = 'published'")

    p "Checking Crossref API for retractions for #{articles.length} resources"

    articles.find_each do |resource|
      article_doi = resource.related_identifiers.find_by(work_type: 'primary_article', related_identifier_type: 'doi')&.related_identifier
      next unless article_doi.present?

      item = Integrations::Crossref.query_by_doi(doi: article_doi)
      update = item&.[]('updated-by')&.find { |u| u['type'] == 'retraction' }
      next unless update.present?

      p "  found retraction for: #{resource.identifier.identifier}"
      Stash::Import::Crossref.new(resource: resource, json: update).to_retraction_note
    end
  end

end
# :nocov:
