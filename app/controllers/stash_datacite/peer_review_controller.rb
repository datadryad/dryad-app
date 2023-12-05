module StashDatacite
  class PeerReviewController < ApplicationController
    include StashEngine::MetadataEntryPagesHelper
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

      respond_to(&:js)
    end

    def release
      if current_user
        begin
          @resource = StashEngine::Resource.find(peer_review_params[:id])
          @error_list = StashDatacite::Resource::DatasetValidations.new(resource: @resource).errors
          @resource.hold_for_peer_review = false
          @resource.peer_review_end_date = nil

          if @error_list.empty?
            @resource.curation_activities << StashEngine::CurationActivity.create(user_id: current_user.id,
                                                                                  status: 'submitted',
                                                                                  note: 'Release from PPR')
          end

          @resource.save
          @resource.reload

          if @error_list.empty?
            redirect_to dashboard_path, notice: 'Dataset released from private for peer review and submitted for curation'
          else
            duplicate_resource
            redirect_to stash_url_helpers.review_resource_path(@new_res.id),
                        alert: 'Unable to submit dataset for curation. Please correct submission errors.'
          end
        rescue ActiveRecord::RecordInvalid
          @error = 'Unable to edit peer review status at this time.'
        end
      else
        redirect_to root_path, error: 'Must be logged in to edit peer review status'
      end

      respond_to(&:html)
    end

    private

    def peer_review_params
      params.require(:stash_engine_resource).permit(:id, :hold_for_peer_review)
    end

  end
end
