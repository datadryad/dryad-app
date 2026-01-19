module PublicationMixin

  private

  def release_resource(resource)
    return unless resource == resource.identifier.latest_resource
    return unless resource.current_curation_status == 'peer_review'

    resource.update(hold_for_peer_review: false, peer_review_end_date: nil)

    if resource.identifier.payment_needed?
      CurationService.new(resource: resource, status: 'awaiting_payment', note: 'Full DPC payment required').process
      StashEngine::UserMailer.peer_review_payment_needed(resource).deliver_now if resource.payment.invoice_id.blank?
    else
      CurationService.new(
        resource: resource,
        user_id: 0, # system user
        status: 'queued',
        note: 'Release from peer review through publication information'
      ).process
      StashEngine::UserMailer.peer_review_pub_linked(resource).deliver_now
    end
  end

  def check_resource_payment(resource)
    return unless resource.identifier.publication_date.blank?
    return unless resource.submitted?

    resource.identifier.record_payment
  end
end
