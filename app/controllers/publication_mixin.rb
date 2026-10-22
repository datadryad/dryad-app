module PublicationMixin

  private

  def release_resource(resource)
    return unless resource == resource.identifier.latest_resource
    return unless resource.current_curation_status == 'peer_review'

    resource.update(hold_for_peer_review: false)

    if resource.identifier.payment_needed?
      CurationService.new(resource: resource, status: 'awaiting_payment', note: 'Full DPC payment required').process
      StashEngine::ResourceMailer.peer_review_payment_needed(resource).deliver_now
    else
      resource.update(user_id: nil) unless resource.curator&.curator?
      CurationService.new(
        resource: resource,
        user_id: 0, # system user
        status: 'queued',
        note: 'Release from peer review through publication information'
      ).process
      StashEngine::ResourceMailer.peer_review_pub_linked(resource).deliver_now
    end
  end

  def reject_manuscript(resource, integration, user_id = 0)
    return unless resource == resource.identifier.latest_resource

    resource.resource_publication.update(publication_name: nil, publication_issn: nil)
    CurationService.new(resource: resource, user_id: user_id, status: resource.current_curation_status,
                        note: "manuscript rejected through #{integration}").process

    check_resource_payment(resource)
    return unless resource.identifier.payment_needed?
    return unless resource.current_curation_status == 'peer_review'
    return if resource.identifier.payments.last.ppr_fee_paid?

    resource.update(hold_for_peer_review: false)
    CurationService.new(resource: resource, status: 'awaiting_payment', note: 'Sponsoring journal removed and DPC payment required').process
    StashEngine::ResourceMailer.payment_needed(resource).deliver_now
  end

  def check_resource_payment(resource)
    return if resource.identifier.published? || resource.identifier.publication_date.present?
    return unless resource.submitted?

    resource.identifier.record_payment
  end
end
