class SponsoredPaymentsService
  attr_reader :resource, :identifier, :payer

  def initialize(resource)
    @resource = resource
    @identifier = resource.identifier
    @payer = @identifier.payer
  end

  def loggable?
    # do not log payment if dataset is set for PPR
    return false if resource.hold_for_peer_review?

    # do not log for items with first submitted date older than 2026-01-01
    fss = resource.identifier.process_date&.processing
    return false if fss && fss < Date.new(2026, 1, 1)
    # there is no payer
    return false if payer.nil?
    # payer is not on 2025 plan
    return false unless PayersService.new(payer).is_2025_payer?
    # payer does not cover ldf
    return false unless PayersService.new(payer).sponsored_limits&.covers_ldf?

    true
  end

  def log_payment
    return unless loggable?

    @calculator_service = calculator_service
    SponsoredPaymentLog.transaction do
      should_skip_log = false
      paid_before = delete_larger_file_size_logs
      amount = ldf_fees(paid_before)

      should_skip_log = true if amount <= 0
      should_skip_log = true if !should_skip_log && PaymentLimitsService.new(resource, payer).exceeds_sponsor_yearly_limit?(amount)

      update_identifier_files_size
      return if should_skip_log

      SponsoredPaymentLog.create(
        resource: resource,
        payer: payer,
        ldf: amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
    end
  end

  def remove_logs
    logs_to_delete = identifier.sponsored_payment_logs
    published_activity = identifier.last_published_status
    logs_to_delete = logs_to_delete.where(created_at: [published_activity.created_at..]) if published_activity.present?

    logs_to_delete.map(&:destroy)
  end

  private

  def update_identifier_files_size
    identifier.update(last_invoiced_file_size: resource.total_file_size)
  end

  def ldf_fees(size = nil)
    @calculator_service.ldf_sponsored_amount(paid_storage_size: size)
  end

  def calculator_service
    calculator_service_class.new({}, resource: resource, payer_record: payer)
  end

  def calculator_service_class
    payer_type = case payer.class.name
                 when 'StashEngine::Funder', 'StashEngine::Journal'
                   'publisher'
                 when 'StashEngine::Tenant'
                   'institution'
                 end
    FeeCalculatorService.new(payer_type).calculator_service
  end

  def delete_larger_file_size_logs
    paid_before = identifier.last_invoiced_file_size.to_i

    if paid_before > resource.total_file_size
      new_tier = calculator_service.storage_fee_tier
      resource.previous_resources.each do |res|
        return res.total_file_size if res.status_published?

        res_tier = calculator_service_class.new({}, resource: res).storage_fee_tier
        if new_tier[:price] < res_tier[:price]
          res.sponsored_payment_log&.destroy
        else
          paid_before = res.total_file_size
          break
        end
      end
      return 0 if identifier.sponsored_payment_logs.none?
    end

    paid_before
  end
end
