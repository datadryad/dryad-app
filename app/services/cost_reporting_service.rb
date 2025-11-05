class CostReportingService
  attr_reader :resource

  def initialize(resource)
    @resource = resource
    @status = resource.current_curation_status
    @note = "Sending large data notification for status: #{@status}"
  end

  def notify_partner_of_large_data_submission
    return unless should_send_notification?

    CurationService.new(status: @status, resource: resource, user: StashEngine::User.system_user, note: @note).process
    StashEngine::ResourceMailer.ld_submission(resource).deliver_later
  end

  private

  def should_send_notification?
    # NO - no emails to send to
    return false if resource.tenant&.campus_contacts&.blank?

    # NO - wrong status
    return false unless @status.in?(%w[submitted embargoed published])

    # NO - not the first status occurrence on resource
    return false if resource.curation_activities.where(status: @status).count > 1

    # NO - payer is an individual user
    return false if resource.identifier.user_must_pay?

    ldf_tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
    # NO - is not a large data submission
    return false if ldf_tier.nil? || ldf_tier[:price] == 0

    prev_resource = previous_notifiable_resource
    # YES - this is the first submission for this identifier
    return true if prev_resource.nil?

    prev_ldf_tier = ResourceFeeCalculatorService.new(prev_resource).storage_fee_tier
    # YES - data fee tier changed
    return true if prev_ldf_tier[:range].max < ldf_tier[:range].max

    # NO - previous notification was already sent for this resource
    return false if resource.curation_activities.where(note: @note).exists?

    true
  end

  def previous_notifiable_resource
    resource.previous_resources.each do |prev|
      return prev if prev.current_curation_status.in?(allowed_statuses)
    end
    nil
  end

  def allowed_statuses
    return %w[submitted curation action_required embargoed to_be_published published] if @status == 'submitted'

    %w[embargoed published]
  end
end
