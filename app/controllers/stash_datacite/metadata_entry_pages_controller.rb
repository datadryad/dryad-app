module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, session[:resource_type] || 'dataset', current_tenant)
      @metadata_entry.resource_type
      @metadata_entry.resource_publications
      @metadata_entry.descriptions

      @submission = @resource.as_json(include: [:identifier, :subjects, :descriptions, :resource_publication, :related_identifiers, :contributors, :resource_type, authors: {include: [:affiliations]}])
      @submission[:generic_files] = @resource.generic_files.validated_table.as_json(
        methods: :type, include: { frictionless_report: { only: %i[report status] } }
      )
      @submission = @submission.to_json

      @resource.update(updated_at: Time.current)

      # If the most recent Curation Activity was from the "Dryad System", add an entry for the
      # current_user so the history makes more sense.
      last_activity = @resource.curation_activities.last
      if last_activity&.user_id == 0
        @resource.curation_activities << StashEngine::CurationActivity.create(status: last_activity.status, user_id: current_user.id, note: 'Editing')
      end
      respond_to(&:js)
    end

    private

    def find_resource
      @resource = StashEngine::Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end
  end
end
