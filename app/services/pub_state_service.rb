class PubStateService
  attr_reader :identifier
  def initialize(identifier)
    @identifier = identifier
  end

  # update identifier pub_state based on CurationActivity status
  def update_for_ca_status(status)
    identifier.update(pub_state: from_ca_status(status))
  end

  # update identifier pub_state based on CurationActivity history
  def update_from_history
    identifier.update(pub_state: identifier.calculated_pub_state)
  end

  private

  def from_ca_status(status)
    return status if status.in?(%w[withdrawn embargoed published retracted])

    'unpublished'
  end
end
