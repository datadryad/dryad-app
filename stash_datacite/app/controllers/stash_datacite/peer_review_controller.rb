require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class PeerReviewController < ApplicationController
    respond_to :json

    # PATCH /peer_review/toggle
    def toggle
      @help_email = APP_CONFIG[:contact_email].last || 'help@datadryad.org'
      @resource = StashEngine::Resource.find(peer_review_params[:id])

      begin
        @resource.hold_for_peer_review = peer_review_params[:hold_for_peer_review]
        toggle_peer_review_status! if @resource.hold_for_peer_review_changed?
      rescue ActiveRecord::RecordInvalid
        @error = 'Unable to enable peer review status at this time.'
      end

      respond_to do |format|
        format.js
      end
    end

    private

    def peer_review_params
      params.require(:resource).permit(:id, :hold_for_peer_review)
    end

    def toggle_peer_review_status!
      # Do not allow this functionality if the item is in curation, published or embargoed
      return unless %w[in_progress submitted].include?(@resource.current_curation_status)

      status = @resource.hold_for_peer_review? ? 'peer_review' : 'submitted'
      verb = @resource.hold_for_peer_review? ? 'enabled' : 'ended'

      # If the user enabled peer review, set the end date to 6 months ahead
      # If the user disabled peer review, set the end date to now unless the resource not
      #   yet been submitted which would indicate an enable/disable before submission (user change mind)
      end_date = @resource.hold_for_peer_review? ? (Time.now + 6.months) : (@resource.submitted? ? Time.now : nil)

p "STATUS: #{status}, VERB: #{verb}, DATE: #{end_date}, CURRENT STATE: #{@resource.current_state}"

      # Add the peer review status if the resource is already submitted through Merritt otherwise
      # the post Merritt submission logic will place it in the correct state
      StashEngine::CurationActivity.create(
        resource_id: @resource.id,
        user_id: current_user.id,
        status: status,
        note: "manually #{verb} Private for Peer Review") if @resource.submitted?

      @resource.update(peer_review_end_date: end_date)
    end

  end
end
