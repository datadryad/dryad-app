module PublicationMixin

  private

  def release_resource(resource)
    return unless resource.hold_for_peer_review

    resource.update(hold_for_peer_review: false, peer_review_end_date: nil)

    return unless resource.current_curation_status == 'peer_review'

    resource.curation_activities << StashEngine::CurationActivity.new(
      user_id: 0, # system user
      status: 'submitted',
      note: 'Release from peer review through publication information'
    )
    StashEngine::UserMailer.peer_review_pub_linked(resource).deliver_now
  end
end
