# :nocov:
namespace :publication_updater do
  desc 'Query pubmed for data connected to articles'
  task query_pubmed: :environment do
    results = StashEngine::Resource.needs_article
    p "Querying PubMed for #{results.length} resources"

    results.find_each do |resource|
      id = resource.identifier.identifier
      begin
        # Query PubMed
        search = Integrations::PubMed.new.esearch(term: id)
        pmid = search.dig('esearchresult', 'idlist', 0)
        doi = Integrations::PubMed.new.doi_by_pmid(pmid)
        # Hit Crossref for info
        cr = Integrations::Crossref.query_by_doi(doi: doi, resource: resource)
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying for identifier: '#{id}': #{e.message}"
        next
      end

      pc = Stash::Import::Crossref.new(resource: resource, json: cr).to_proposed_change if cr.present?
      p "  found changes for: #{id} (#{resource.last_curation_activity.status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    p 'Finished querying PubMed'
  end

  desc 'Get primary article information from associated preprints'
  task query_preprints: :environment do
    # Articles with preprints but no primary article
    results = StashEngine::Resource.needs_article.joins(
      "join dcs_related_identifiers pr on pr.resource_id = stash_engine_resources.id
      and pr.work_type = 3 and pr.related_identifier_type = 'doi' and pr.related_identifier like 'http%'"
    )
      .distinct
    p "Scanning Crossref API for #{results.length} resources"

    results.find_each do |resource|
      preprint = resource.related_identifiers.where(work_type: 'preprint', related_identifier_type: 'doi').first&.related_identifier
      next unless preprint.present?

      begin
        # Hit Crossref for info
        cr = Integrations::Crossref.query_by_preprint_doi(resource: resource, doi: preprint)
      rescue URI::InvalidURIError, MultiJson::ParseError => e
        # If the URI is invalid, just skip to the next record
        # MultiJson::ParseError is for current Serrano redirect bug
        p "ERROR querying Crossref for identifier: '#{resource.identifier.identifier}': #{e.message}"
        next
      end

      pc = Stash::Import::Crossref.new(resource: resource, json: cr).to_proposed_change if cr.present?
      p "  found changes for: #{resource.identifier.identifier} (#{resource.last_curation_activity.status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end
  end

  desc 'Scan Crossref for metadata about active datasets without primary articles'
  task crossref: :environment do
    # Retrive all non-withdrawn datasets that have no primary article already conencted
    results = StashEngine::Resource.needs_article
    p "Scanning Crossref API for #{results.length} resources"

    results.find_each do |resource|
      begin
        # Hit Crossref for info
        cr = Integrations::Crossref.query_by_author_title(resource: resource)
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for identifier: '#{resource.identifier.identifier}': #{e.message}"
        next
      end

      pc = Stash::Import::Crossref.new(resource: resource, json: cr).to_proposed_change if cr.present?
      p "  found changes for: #{resource.identifier.identifier} (#{resource.last_curation_activity.status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    p 'Finished scanning Crossref API'
  end

  desc 'Rescan non-processed proposed changes for metadata updates at crossref'
  task rescan: :environment do
    StashEngine::ProposedChange.unprocessed.each do |existing_pc|
      identifier = existing_pc.identifier
      resource = identifier&.latest_resource
      # remove this from the changes table and try re-adding it
      existing_pc.destroy # and re-import below
      next if resource.nil? || existing_pc.identifier.pub_state == 'withdrawn'

      puts "rescanning existing proposed change id: #{existing_pc.id}, #{existing_pc.title}"

      begin
        # Hit Crossref for info
        cr = Integrations::Crossref.query_by_author_title(resource: resource)
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for publication DOI: '#{result.doi}' for identifier: '#{resource&.identifier}' : #{e.message}"
        next
      end

      pc = Stash::Import::Crossref.new(resource: resource, json: cr).to_proposed_change if cr.present?
      p "  found changes for: #{resource.identifier.identifier} (#{resource.last_curation_activity.status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    puts 'Finished rescanning Crossref API to update existing entries'
  end

end
# :nocov:
