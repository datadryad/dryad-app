require 'stash/import/crossref'

# rubocop:disable Metrics/BlockLength
namespace :publication_updater do

  desc 'Scan Crossref for metadata about unpublished datasets that were created within the past 6 months'
  task crossref: :environment do
    from_date = Date.today - 6.months

    resources = StashEngine::Resource.latest_per_dataset.where('stash_engine_resources.created_at >= ?', from_date)

    p "Scanning Crossref API for #{resources.length} resources"

    resources.each do |resource|
      existing_pc = StashEngine::ProposedChange.where(identifier_id: resource.identifier_id).first
      # Skip any identifiers that already have proposed changes that is approved and published
      # or are already marked as published in Dryad
      next if existing_pc.present? && existing_pc.approved? && existing_pc.publication_date.present?
      next if resource.current_curation_activity.blank? || resource.current_curation_status == 'published'

      # Skip the record if we've already captured its info from Crossref
      next if resource.curation_activities.where('stash_engine_curation_activities.note LIKE ?',
                                                 "%#{StashEngine::ProposedChange::CROSSREF_UPDATE_MESSAGE}").any?

      doi = resource.identifier.internal_data.where(data_type: 'publicationDOI').first

      begin
        cr = Stash::Import::Crossref.query_by_doi(resource: resource, doi: doi.value) if doi.present?
        cr = Stash::Import::Crossref.query_by_author_title(resource: resource) unless cr.present?
      rescue URI::InvalidURIError => iue
        # If the URI is invalid, just skip to the next record
        p "ERROR querying Crossref for '#{doi.value}' : #{iue.message}"
        next
      end

      pc = cr.to_proposed_change if cr.present?
      # Skip the change if we already have proposed changes and the information is not different
      next if existing_pc == pc
      p "  found changes for: #{resource.id} (#{resource&.current_curation_status}) - #{resource.title}" if pc.present?
      pc.save if pc.present?
    end

    p 'Finished scanning Crossref API'

  end

end
# rubocop:enable Metrics/BlockLength