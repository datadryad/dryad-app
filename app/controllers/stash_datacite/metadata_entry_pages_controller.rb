module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, session[:resource_type] || 'dataset', @resource.submitter&.tenant_id)
      @metadata_entry.resource_type
      @metadata_entry.resource_publications
      @metadata_entry.descriptions

      @submission = @resource.as_json(
        include: [:tenant, :resource_type, :resource_publication, :resource_preprint, :journal,
                  :related_identifiers, :edit_histories, :contributors, :subjects, :descriptions,
                  { authors: { methods: [:orcid_invite_path], include: %i[affiliations edit_code] },
                    identifier: { methods: %i[new_upload_size_limit], include: %i[process_date software_license] },
                    previous_curated_resource: {
                      include: [:tenant, :subjects, :descriptions, :resource_publication, :journal, :related_identifiers, :contributors,
                                :action_reports, { authors: { include: [:affiliations] } }]
                    } }]
      )
      @submission[:users] = @resource.users.select('stash_engine_users.*', 'stash_engine_roles.role')
      @submission = @submission.to_json

      @resource.update(updated_at: Time.current, current_editor_id: current_user.id)
      @target_page = stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @resource.id)

      # If the most recent Curation Activity was from the "Dryad System", add an entry for the
      # current_user so the history makes more sense.
      last_activity = @resource.curation_activities.last
      if last_activity&.user_id == 0
        @resource.curation_activities << StashEngine::CurationActivity.create(status: last_activity.status, user_id: current_user.id, note: 'Editing')
      end
      respond_to(&:js)
    end

    def find_files
      files = {}
      files[:generic_files] = @resource.generic_files.includes(:frictionless_report).validated_table.as_json(
        methods: %i[type uploaded], include: { frictionless_report: { only: %i[report status] } }
      )
      if @resource.previous_curated_resource.present?
        files[:previous_files] = @resource.previous_curated_resource.generic_files.includes(:frictionless_report).validated_table.as_json(
          methods: :type, include: { frictionless_report: { only: %i[report status] } }
        )
      end

      render json: files
    end

    private

    def find_resource
      @resource = StashEngine::Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end
  end
end
