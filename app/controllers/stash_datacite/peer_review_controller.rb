module StashDatacite
  class PeerReviewController < ApplicationController
    before_action :require_modify_permission
    respond_to :json

    def resource
      @resource ||= StashEngine::Resource.find(peer_review_params[:id])
    end
    helper_method :resource

    # PATCH /peer_review/toggle
    def toggle
      @help_email = APP_CONFIG[:contact_email].last || 'help@datadryad.org'
      begin
        @resource.hold_for_peer_review = peer_review_params[:hold_for_peer_review]
        @resource.peer_review_end_date = (@resource.hold_for_peer_review? ? Time.now.utc + 6.months : nil)
        @resource.save
      rescue ActiveRecord::RecordInvalid
        @error = 'Unable to enable peer review status at this time.'
      end

      render json: { hold_for_peer_review: peer_review_params[:hold_for_peer_review], error: @error }
    end

    def release
      @errors = StashDatacite::Resource::DatasetValidations.new(resource: @resource).errors
      @not_paid = @resource.identifier.payment_needed?

      if @errors || @not_paid
        new_res = DuplicateResourceService.new(@resource, current_user).call
        new_res.update(hold_for_peer_review: false, peer_review_end_date: nil)

        flash[:alert] = 'Unable to submit dataset for curation. Please correct submission errors' if @errors
        flash[:notice] = 'Please pay the remaining DPC to submit for curation and publication' if @not_paid
        redirect_to stash_url_helpers.metadata_entry_pages_find_or_create_path(resource_id: new_res.id)
      else
        @resource.update(hold_for_peer_review: false, peer_review_end_date: nil)
        @resource.curation_activities << StashEngine::CurationActivity.create(
          user_id: current_user.id, status: 'submitted', note: 'Release from PPR'
        )
        @resource.reload
        redirect_to dashboard_path, notice: 'Dataset released from Private for Peer Review and submitted for curation'
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to dashboard_path, alert: 'Unable to edit peer review status at this time.'
    end

    private

    def peer_review_params
      params.permit(:id, :hold_for_peer_review)
    end

  end
end
