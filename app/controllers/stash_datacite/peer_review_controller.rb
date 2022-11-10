module StashDatacite
  class PeerReviewController < ApplicationController
    respond_to :json

    # PATCH /peer_review/toggle
    def toggle
      @help_email = APP_CONFIG[:contact_email].last || 'help@datadryad.org'
      @resource = StashEngine::Resource.find(peer_review_params[:id])

      begin
        @resource.hold_for_peer_review = peer_review_params[:hold_for_peer_review]
        @resource.peer_review_end_date = (@resource.hold_for_peer_review? ? Time.now.utc + 6.months : nil)
        @resource.save
      rescue ActiveRecord::RecordInvalid
        @error = 'Unable to enable peer review status at this time.'
      end

      respond_to do |format|
        format.js
      end
    end

    private

    def peer_review_params
      params.require(:stash_engine_resource).permit(:id, :hold_for_peer_review)
    end

  end
end
