module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    # rubocop:disable Metrics/MethodLength
    def find_or_create
      @metadata_entry = Resource::MetadataEntry.new(@resource, session[:resource_type] || 'dataset', @resource.submitter&.tenant)
      @metadata_entry.resource_type
      @metadata_entry.resource_publications
      @metadata_entry.descriptions

      @submission = @resource.as_json(
        include: [
          :resource_type, :resource_publication, :resource_preprint,
          :related_identifiers, :edit_histories, :contributors, :subjects, :descriptions,
          { authors: { methods: [:orcid_invite_path], include: %i[affiliations edit_code] },
            identifier: { methods: %i[new_upload_size_limit], include: %i[process_date software_license] },
            previous_curated_resource: {
              include: [
                :subjects, :descriptions, :resource_publication, :related_identifiers, :contributors,
                {
                  authors: { include: [:affiliations] },
                  tenant: { include: %i[payment_configuration] },
                  journal: { include: %i[payment_configuration] }
                }
              ]
            },
            tenant: { include: %i[payment_configuration] },
            journal: { include: %i[payment_configuration] } }
        ]
      )
      @submission[:users] = @resource.users.select('stash_engine_users.*', 'stash_engine_roles.role')
      @submission = @submission.to_json

      @resource.update(updated_at: Time.current, current_editor_id: current_user.id)
      @target_page = stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: @resource.id)

      # If the most recent Curation Activity was from the "Dryad System", add an entry for the
      # current_user so the history makes more sense.
      last_activity = @resource.curation_activities.last
      if last_activity&.user_id == 0
        CurationService.new(resource: @resource, status: last_activity.status, user_id: current_user.id, note: 'Editing').process
      end
      respond_to(&:js)
    end
    # rubocop:enable Metrics/MethodLength

    def find_files
      files = {}
      files[:generic_files] = @resource.generic_files.validated_table.as_json(
        methods: %i[type uploaded frictionless_report]
      )
      if @resource.previous_curated_resource.present?
        files[:previous_files] = @resource.previous_curated_resource.generic_files.validated_table.as_json(
          methods: %i[type frictionless_report]
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
