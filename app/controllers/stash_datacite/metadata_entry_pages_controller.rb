require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, current_tenant)
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
      respond_to do |format|
        format.js
      end
    end

    private

    def find_resource
      @resource = StashEngine::Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end
  end
end
