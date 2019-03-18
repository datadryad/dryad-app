require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, current_tenant)
      @metadata_entry.resource_type
      se_id = StashEngine::Identifier.find(@resource.identifier_id)
      @publication = StashEngine::InternalDatum.find_or_create_by(stash_identifier: se_id, data_type: 'publicationISSN')
      @msid = StashEngine::InternalDatum.find_or_create_by(stash_identifier: se_id, data_type: 'manuscriptNumber')

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
