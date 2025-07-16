module PublicationMixin
  include StashEngine::MetadataEntryPagesHelper

  private

  def release_resource(resource)
    return unless resource == resource.identifier.latest_resource
    return unless resource.current_curation_status == 'peer_review'

    if resource.identifier.payment_needed?
      duplicate_resource
      @new_res.update(hold_for_peer_review: false, peer_review_end_date: nil)
      @new_res.curation_activities.last.update(note: 'Full DPC payment required')
      StashEngine::UserMailer.peer_review_payment_needed(@new_res).deliver_now
    else
      resource.update(hold_for_peer_review: false, peer_review_end_date: nil)
      resource.curation_activities << StashEngine::CurationActivity.new(
        user_id: 0, # system user
        status: 'submitted',
        note: 'Release from peer review through publication information'
      )
      StashEngine::UserMailer.peer_review_pub_linked(resource).deliver_now
    end
  end
end
