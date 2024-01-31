module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, session[:resource_type] || 'dataset', current_tenant)
      @metadata_entry.resource_type
      se_id = StashEngine::Identifier.find(@resource.identifier_id)
      @publication_issn = StashEngine::InternalDatum.find_or_initialize_by(stash_identifier: se_id, data_type: 'publicationISSN')
      @publication_name = StashEngine::InternalDatum.find_or_initialize_by(stash_identifier: se_id, data_type: 'publicationName')
      @msid = StashEngine::InternalDatum.find_or_initialize_by(stash_identifier: se_id, data_type: 'manuscriptNumber')

      # the following used a "find_or_initialize" originally, but it doesn't always load the existing record
      # some dois not identified as such, but as URLs probably from the live-checking code and crossRef and DataCite fight
      @doi = @resource.related_identifiers.where(work_type: 'primary_article').first
      if @doi.blank?
        @doi = StashDatacite::RelatedIdentifier.new(resource_id: @resource.id, related_identifier_type: 'doi',
                                                    work_type: 'primary_article')
      end
      @resource.update(updated_at: Time.current)
      respond_to(&:js)

      # If the most recent Curation Activity was from the "Dryad System", add an entry for the
      # current_user so the history makes more sense.
      # rubocop:disable Style/GuardClause
      last_activity = @resource.curation_activities.last
      if last_activity&.user_id == 0
        @resource.curation_activities << StashEngine::CurationActivity.create(status: last_activity.status, user_id: current_user.id, note: 'Editing')
      end
      # rubocop:enable Style/GuardClause
    end

    def cedar_check
      # rubocop:disable Style/DoubleNegation
      @metadata_entry = Resource::MetadataEntry.new(@resource, session[:resource_type] || 'dataset', current_tenant)
      se_id = StashEngine::Identifier.find(@resource.identifier_id)
      publication_name = StashEngine::InternalDatum.find_or_initialize_by(stash_identifier: se_id, data_type: 'publicationName').value || ''
      title = @resource.title || ''
      abstract = @metadata_entry.abstract.description || ''
      @neuro_data = false
      bank = %w[neuro cogniti cereb]
      regex = bank.join('|')
      keywords = @metadata_entry.subjects.map(&:subject).join(', ')
      if !!title.match?(/#{regex}/i) || !!publication_name.match?(/#{regex}/i) || !!keywords.match?(/#{regex}/i) || !!abstract.match?(/#{regex}/i)
        @neuro_data = true
      end
      respond_to(&:html)
      # rubocop:enable Style/DoubleNegation
    end

    private

    def find_resource
      @resource = StashEngine::Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end
  end
end
