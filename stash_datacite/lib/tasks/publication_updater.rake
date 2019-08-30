require 'stash/import/crossref'

# rubocop:disable Metrics/BlockLength
namespace :publication_updater do

  # Query to retrieve the latest resource and its latest curation activity
  # where the status is not in_progress (Merritt has already processed it) and not published
  # and its most recent curation activity was within the past 6 months
  QUERY = <<-SQL.freeze
    SELECT ser.id, ser.identifier_id, seca.status, dri.related_identifier, ser.title, sepc.id
    FROM stash_engine_resources ser
      INNER JOIN stash_engine_identifiers sei ON ser.identifier_id = sei.id
      LEFT OUTER JOIN dcs_related_identifiers dri ON ser.id = dri.resource_id
        AND dri.relation_type = 'issupplementto' AND dri.related_identifier_type = 'doi'
      INNER JOIN (SELECT MAX(r2.id) r_id FROM stash_engine_resources r2 GROUP BY r2.identifier_id) j1 ON j1.r_id = ser.id
      LEFT OUTER JOIN (SELECT ca2.resource_id, MAX(ca2.id) latest_curation_activity_id FROM stash_engine_curation_activities ca2 GROUP BY ca2.resource_id) j3 ON j3.resource_id = ser.id
      LEFT OUTER JOIN stash_engine_curation_activities seca ON seca.id = j3.latest_curation_activity_id
      LEFT OUTER JOIN (SELECT sepc2.identifier_id, MAX(sepc2.id) latest_proposed_change_id FROM stash_engine_proposed_changes sepc2 GROUP BY sepc2.identifier_id) j4 ON j4.identifier_id = sei.id
      LEFT OUTER JOIN stash_engine_proposed_changes sepc ON sepc.id = j4.latest_proposed_change_id AND sepc.approved != 1
    WHERE seca.status NOT IN ('in_progress', 'published', 'embargoed')
  SQL

  desc 'Scan Crossref for metadata about unpublished datasets that were created within the past 6 months'
  task crossref: :environment do
    # We only want to harass Crossref with DOIs of datasets that have been curated within the past 6 months
    from_date = (Time.now - 6.months).strftime('%Y-%m-%d %H:%M:%S')

    results = ActiveRecord::Base.connection.execute("#{QUERY} AND seca.created_at >= '#{from_date}'").map do |rec|
      OpenStruct.new(resource_id: rec[0], identifier_id: rec[1], status: rec[2], doi: rec[3], title: rec[4], change_id: rec[5])
    end
    p "Scanning Crossref API for #{results.length} resources"

    results.each do |result|
      # Skip the record if we've already captured its info from Crossref at any point
      next if StashEngine::CurationActivity.where(resource_id: result.resource_id)
          .where('stash_engine_curation_activities.note LIKE ?', "%#{StashEngine::ProposedChange::CROSSREF_UPDATE_MESSAGE}").any?

      begin
        resource = StashEngine::Resource.find(result.resource_id)

        # Hit Crossref for info
        cr = Stash::Import::Crossref.query_by_doi(resource: resource, doi: result.doi) if result.doi.present?
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource) unless cr.present?
      rescue URI::InvalidURIError => iue
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for publication DOI: '#{result.doi}' for identifier: '#{resource&.identifier}' : #{iue.message}"
        next
      end

      pc = cr.to_proposed_change if cr.present?
      # Skip the change if we already have proposed changes and the information is not different
      existing_pc = StashEngine::ProposedChange.find(result.change_id) if result.change_id.present?
      next if existing_pc == pc

      # Tweakable threshold for scoring (score is ours ... 1 == DOI match, < 1 is title+authors matching)
      #                                 (provenance_score is Crossref's score)
      next unless pc.present? && pc.score >= 0.6

      p "  found changes for: #{result.resource_id} (#{result.status}) - #{result.title}" if pc.present?
      pc.save if pc.present?
    end

    p 'Finished scanning Crossref API'
  end

end
# rubocop:enable Metrics/BlockLength
