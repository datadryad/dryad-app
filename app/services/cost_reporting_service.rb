class CostReportingService
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def notify_partner_of_large_data_submission
    status = resource.current_curation_status
    note = "Large Data notification was sent for status: #{status}"
    return if resource.curation_activities.where(note: note).exists?

    CurationService.new(status: status, resource: resource, user: StashEngine::User.system_user, note: note).create
    ResourceMailer.ld_submission(resource).deliver_later
  end

end
