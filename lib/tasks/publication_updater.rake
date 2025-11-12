# :nocov:
namespace :publication_updater do

  desc 'Scan Crossref for metadata about datasets that were curated within the past year'
  task crossref: :environment do
    # Retrive all non-withdrawn datasets that have no primary article already conencted
    results = StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity)
      .joins('left outer join dcs_related_identifiers pa on pa.resource_id = stash_engine_resources.id and pa.work_type = 6')
      .where("pa.id is null and stash_engine_identifiers.pub_state != 'withdrawn'")
      .where.not(last_curation_activity: { status: 'withdrawn' })
    p "Scanning Crossref API for #{results.length} resources"

    results.find_each do |resource|
      begin
        # Hit Crossref for info
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource)
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for identifier: '#{resource.identifier.identifier}': #{e.message}"
        next
      end

      pc = cr.to_proposed_change if cr.present?
      p "  found changes for: #{resource.identifier.identifier} (#{resource.last_curation_activity.status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    p 'Finished scanning Crossref API'
  end

  # THERE was a lot of junk data on our dev machine and orphaned proposed changes for identifiers that didn't exist.
  # cleanup the table like this:

  # DELETE pc FROM `stash_engine_proposed_changes` pc
  # LEFT JOIN stash_engine_identifiers i
  # ON pc.identifier_id = i.id
  # WHERE i.id IS NULL;

  # NOTE: This will fill in the subjects and also get a type from crossref
  desc 'Rescan non-processed proposed changes for metadata updates at crossref'
  task rescan: :environment do
    StashEngine::ProposedChange.where(approved: false, rejected: false).each do |existing_pc|
      identifier = existing_pc.identifier
      resource = identifier&.latest_resource
      primary_article = resource&.related_identifiers&.primary_article&.first
      # remove this from the changes table and try re-adding it
      next if resource.nil? || existing_pc.identifier.pub_state == 'withdrawn'

      puts "rescanning existing proposed change id: #{existing_pc.id}, #{existing_pc.title}"

      existing_pc.destroy # and re-import below

      begin
        # Hit Crossref for info
        if primary_article&.related_identifier.present?
          cr = Stash::Import::Crossref.query_by_doi(resource: resource,
                                                    doi: primary_article.related_identifier)
        end
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource) unless cr.present?
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for publication DOI: '#{result.doi}' for identifier: '#{resource&.identifier}' : #{e.message}"
        next
      end

      pc = cr.to_proposed_change if cr.present?
      p "  found changes for: #{resource.id} (#{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    puts 'Finished rescanning Crossref API to update existing entries'
  end

end
# :nocov:
