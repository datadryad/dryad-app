class SponsoredPaymentsService
  attr_reader :resource, :identifier, :payer

  def initialize(resource)
    @resource = resource
    @identifier = resource.identifier
    @payer = @identifier.payer
  end

  def log_payment
    # there is no payer
    return if payer.nil?
    # user is not on 2025 plan
    return unless PayersService.new(payer).is_2025_payer?

    @calculator_service = calculator_service
    SponsoredPaymentLog.transaction do
      paid_before = delete_larger_file_size_logs
      amount = ldf_fees(paid_before)
      update_identifier_files_size and return if amount.zero?

      SponsoredPaymentLog.create(
        resource: resource,
        payer: payer,
        ldf: amount,
        sponsor_id: PayersService.new(payer).payment_sponsor&.id
      )
      update_identifier_files_size
    end
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
          res.sponsored_payment_log.destroy
        else
          paid_before = res.total_file_size
          break
        end
      end
    end
    return 0 if identifier.sponsored_payment_logs.none?

    paid_before
  end
end
