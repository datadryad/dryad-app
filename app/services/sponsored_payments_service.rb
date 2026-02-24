class SponsoredPaymentsService
  attr_reader :resource, :payer

  def initialize(resource)
    @resource = resource
    @payer = resource.identifier.payer
  end

  def log_payment
    # there is no payer
    return if payer.nil?
    # user is flagged to pay
    return if resource.identifier.user_must_pay?
    # user is not on 2025 plan
    return unless PayersService.new(payer).is_2025_payer?

    # for this resource, there is an invoice or user already paid/failed with CC
    payment = resource.payment
    if payment
      # resource already has an invoice created
      return if payment.pay_with_invoice?
      # or a paid/failed CC payment
      return if !payment.pay_with_invoice? && payment.paid?
      return if !payment.pay_with_invoice? && payment.failed?
    end

    amount = ldf_fees
    return if amount.zero?

    SponsoredPaymentLog.create(
      resource: resource,
      payer: payer,
      ldf: ldf_fees,
      sponsor_id: payer.sponsor_id
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
    FeeCalculatorService.new(payer_type).ldf_amount(resource: resource, payer: payer)
  end

  def sponsor_id
    payer.sponsor_id
  end
end
