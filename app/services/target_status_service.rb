class TargetStatusService
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def curator_override?
    prev_submitted = @resource.identifier.last_submitted_status
    if prev_submitted&.status == 'peer_review'
      peer_review_set = @resource.identifier.curation_activities.where(status: 'peer_review', user_id: StashEngine::User.curators.pluck(:id))
      return true if peer_review_set&.any?(&:curation_status_changed?)
    end

    false
  end

  def allow_ppr?
    return false if @resource.identifier.accepted_for_publication? || @resource.identifier.published?
    return true if curator_override?
    return false if @resource.identifier.last_curated_status.present?

    true
  end

  def status
    return 'peer_review' if @resource.hold_for_peer_review? && allow_ppr?
    return 'awaiting_payment' if @resource.identifier.payment_needed?

    'queued'
  end

  def set_target_status
    target = status
    # set user from prev activity, otherwise resource editor_id and then user_id
    user_id = @resource.identifier.last_curation_activity.user_id.presence || @resource.current_editor_id || @resource.user_id

    @resource.update(hold_for_peer_review: false) unless target == 'peer_review'
    CurationService.new(resource_id: @resource.id, user_id: user_id, status: target, note: curation_note).process
    @resource.reload

    target
  end

  private

  def curation_note
    if status == 'peer_review'
      str = 'Set to private for peer review '
      str += if curator_override?
               'by curator'
             elsif @resource.identifier.automatic_ppr?
               'due to journal integration'
             else
               'by submitter'
             end
      return str
    end

    return 'Invoice must be paid before curation' if status == 'awaiting_payment'

    'Queued for curation'
  end
end
