module StashApi
  class RelatedWorksController < ApiApplicationController

    before_action :require_json_headers
    before_action :force_json_content_type
    before_action :doorkeeper_authorize!, only: %i[update]
    before_action :require_api_user, only: %i[update]
    before_action :require_limited_curator, only: %i[update]
    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: %i[update]
    before_action :require_good_doi, only: %i[update]
    before_action :require_valid_work_type, only: %i[update]

    # PUT
    def update
      # update dataset
      @resource = @stash_identifier.latest_resource
      related = StashDatacite::RelatedIdentifier.upsert_simple_relation(doi: @other_doi,
                                                              resource_id: @resource.id,
                                                              work_type: params[:work_type],
                                                              added_by: 'api_simple',
                                                              verified: true)

      # Notify submitter and curators if not notified of an update to this dataset in the last 24 hours
      send_email

      # add curation activity for update
      last_curation = @resource.curation_activities.last
      StashEngine::CurationActivity.create(resource_id: @resource.id,
                                           user_id: @user.id,
                                           status: last_curation.status,
                                           note: "Related #{params[:work_type]} added with #{@other_doi}} from the API",
                                           created_at: Time.now)

      render json: {
        relationship: related.work_type,
        identifierType: related.related_identifier_type_friendly,
        identifier: related.related_identifier
      }
    end

    private

    def require_good_doi
      @other_doi = StashDatacite::RelatedIdentifier.standardize_doi(params[:id])
      good = StashDatacite::RelatedIdentifier.valid_doi_format?(@other_doi)
      render json: { error: "bad request: related DOI isn't formatted correctly" }.to_json, status: 400 unless good
    end

    def require_valid_work_type
      return if StashDatacite::RelatedIdentifier.work_types.keys.include?(params[:work_type])

      render json: { error: "bad request: work_type is invalid, please choose from #{StashDatacite::RelatedIdentifier.work_types.keys.join(', ')}" }.to_json, status: 400
    end

    def send_email
      last_cur = @resource.last_curation_activity
      last_note = last_cur&.note || ''
      return if last_note.match(/Related .+ added with http.+ from the API/) && last_cur.created_at > 1.day.ago

      StashEngine::UserMailer.related_work_updated(@resource).deliver_now
    end
  end
end
