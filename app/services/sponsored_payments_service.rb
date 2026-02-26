class SponsoredPaymentsService
  attr_reader :resource, :payer

  def initialize(resource)
    @resource = resource
    @payer = resource.identifier.payer
  end

  def log_payment
    # there is no payer
    return if payer.nil?
    # user is not on 2025 plan
    return unless PayersService.new(payer).is_2025_payer?

    amount = ldf_fees
    return if amount.zero?

    SponsoredPaymentLog.create(
      resource: resource,
      payer: payer,
      ldf: ldf_fees,
      sponsor_id: PayersService.new(payer).payment_sponsor&.id
    )
    resource.identifier.update(last_invoiced_file_size: resource.total_file_size)
  end

  private

  def ldf_fees
    payer_type = case payer.class.name
                 when 'StashEngine::Funder', 'StashEngine::Journal'
                   'publisher'
                 when 'StashEngine::Tenant'
                   'institution'
                 end
    FeeCalculatorService.new(payer_type).ldf_sponsored_amount(resource: resource, payer: payer)
  end
end
