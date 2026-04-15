class PaymentLimitsService
  attr_reader :resource, :payer, :sponsor, :ldf_sponsored_amount, :payment_configuration

  def initialize(resource, payer, ldf_sponsored_amount: nil)
    @resource = resource
    @payer = payer
    @sponsor = PayersService.new(payer).payment_sponsor
    @ldf_sponsored_amount = ldf_sponsored_amount
    @payment_configuration = PayersService.new(payer).sponsored_limits
    set_calculator_service
  end

  def payment_allowed?
    !limits_exceeded?
  end

  def size_limits_exceeded?
    early_return = verify_basics
    return early_return unless early_return.nil?
    return false if payment_configuration.ldf_limit.nil?

    # true - if the new files size is over the LDF size limit
    ldf_limit_exceeded
  end

  def amount_limits_exceeded?
    early_return = verify_basics
    return early_return unless early_return.nil?
    return false if payment_configuration.yearly_ldf_limit.nil?

    exceeds_yearly_ldf_limit?
  end

  def limits_exceeded?
    early_return = verify_basics
    return early_return unless early_return.nil?

    amount_limits_exceeded? || size_limits_exceeded?
  end

  def exceeds_sponsor_yearly_limit?(storage_fee)
    return false if sponsor.nil?
    return false if payment_configuration&.yearly_ldf_limit.nil?

    paid_amount = SponsoredPaymentLog.for_current_year.where(sponsor_id: sponsor.id).sum(:ldf)
    paid_amount + storage_fee > payment_configuration.yearly_ldf_limit.to_f
  end

  private

  def verify_basics
    return true if sponsor.nil?

    @storage_fee = ldf_sponsored_amount || @calculator_service.ldf_sponsored_amount(resource: resource, payer: payer)
    return false if @storage_fee.zero?
    return true unless payment_configuration&.covers_ldf

    nil
  end

  def exceeds_yearly_ldf_limit?
    exceeds_sponsor_yearly_limit?(@storage_fee)
  end

  def set_calculator_service
    payer_type = case payer.class.name
                 when 'StashEngine::Funder', 'StashEngine::Journal'
                   'publisher'
                 when 'StashEngine::Tenant'
                   'institution'
                 end
    @calculator_service = FeeCalculatorService.new(payer_type)
  end

  def ldf_limit_exceeded
    return false if payment_configuration.ldf_limit.nil?

    tier = @calculator_service.sponsored_tier(payer)
    tier[:range].max < resource.total_file_size.to_i
  end
end
