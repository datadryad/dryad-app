namespace :publication_updater do

  # Query to retrieve the latest resource and its latest curation activity
  # where the status is not in_progress (Merritt has already processed it) and not published
  # and its most recent curation activity was within the past 6 months
  query = <<-SQL.freeze
    SELECT ser.id, ser.identifier_id, seca.status, dri.related_identifier, ser.title, sepc.id
    FROM stash_engine_identifiers sei
      INNER JOIN stash_engine_resources ser ON sei.latest_resource_id = ser.id#{' '}
      LEFT OUTER JOIN dcs_related_identifiers dri ON ser.id = dri.resource_id
        AND dri.work_type = 'primary_article' AND dri.related_identifier_type = 'doi'
      INNER JOIN stash_engine_curation_activities seca ON ser.last_curation_activity_id = seca.id
      LEFT OUTER JOIN (SELECT sepc2.identifier_id, MAX(sepc2.id) latest_proposed_change_id FROM stash_engine_proposed_changes sepc2 GROUP BY sepc2.identifier_id) j4 ON j4.identifier_id = sei.id
      LEFT OUTER JOIN stash_engine_proposed_changes sepc ON sepc.id = j4.latest_proposed_change_id AND sepc.approved != 1
    WHERE seca.status NOT IN ('in_progress', 'published', 'embargoed')
  SQL

  desc 'Scan Crossref for metadata about unpublished datasets that were created within the past 6 months'
  task crossref: :environment do
    # We only want to harass Crossref with DOIs of datasets that have been curated within the past 6 months
    from_date = (Time.now - 6.months).strftime('%Y-%m-%d %H:%M:%S')

    results = ActiveRecord::Base.connection.execute("#{query} AND seca.created_at >= '#{from_date}'").map do |rec|
      OpenStruct.new(resource_id: rec[0], identifier_id: rec[1], status: rec[2], doi: rec[3], title: rec[4], change_id: rec[5])
    end
    p "Scanning Crossref API for #{results.length} resources"

    results.each do |result|
      # Skip the record if we've already captured its info from Crossref at any point
      next if StashEngine::CurationActivity.where(resource_id: result.resource_id)
        .where('stash_engine_curation_activities.note LIKE ?', "%#{StashEngine::ProposedChange::CROSSREF_UPDATE_MESSAGE}").any?

      begin
        resource = StashEngine::Resource.find(result.resource_id)
        next if resource.nil? || resource.identifier.blank? || resource.identifier.pub_state == 'withdrawn'

        # Hit Crossref for info
        cr = Stash::Import::Crossref.query_by_doi(resource: resource, doi: result.doi) if result.doi.present?
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource) unless cr.present?
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for publication DOI: '#{result.doi}' for identifier: '#{resource&.identifier}' : #{e.message}"
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

  # THERE was a lot of junk data on our dev machine and orphaned proposed changes for identifiers that didn't exist.
  # cleanup the table like this:

  # DELETE pc FROM `stash_engine_proposed_changes` pc
  # LEFT JOIN stash_engine_identifiers i
  # ON pc.identifier_id = i.id
  # WHERE i.id IS NULL;

  # note:  This will fill in the subjects and also get a type from crossref
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
        cr = Stash::Import::Crossref.query_by_doi(resource: resource, doi: primary_article.related_identifier) if primary_article&.related_identifier.present?
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource) unless cr.present?
      rescue URI::InvalidURIError => e
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for publication DOI: '#{result.doi}' for identifier: '#{resource&.identifier}' : #{e.message}"
        next
      end

      pc = cr.to_proposed_change if cr.present?

      # Tweakable threshold for scoring (score is ours ... 1 == DOI match, < 1 is title+authors matching)
      #                                 (provenance_score is Crossref's score)
      next unless pc.present? && pc.score >= 0.6

      p "  found changes for: #{resource.id} (#{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    puts 'Finished rescanning Crossref API to update existing entries'
  end

end
