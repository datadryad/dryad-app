class PaymentLimitsService
  attr_reader :resource, :payer

  def initialize(resource, payer)
    @resource = resource
    @payer = payer
    set_calculator_service
  end

  def payment_allowed?
    !limits_exceeded?
  end

  def size_limits_exceeded?
    return true if payer.nil?
    return false unless PayersService.new(payer).is_2025_payer?
    return true unless payer.payment_configuration&.covers_ldf

    # true - if the new files size is over the LDF size limit
    ldf_limit_exceeded
  end

  def amount_limits_exceeded?
    return true if payer.nil?
    return false unless PayersService.new(payer).is_2025_payer?
    return true unless payer.payment_configuration&.covers_ldf

    exceeds_yearly_ldf_limit?
  end

  def limits_exceeded?
    return true if payer.nil?
    return false unless PayersService.new(payer).is_2025_payer?
    return true unless payer.payment_configuration&.covers_ldf

    amount_limits_exceeded? || size_limits_exceeded?
  end

  private

  def exceeds_yearly_ldf_limit?
    storage_fee = @calculator_service.ldf_amount(resource: resource, payer: payer).to_f
    return false if storage_fee.zero?

    exceeds_payer_yearly_limit?(storage_fee) || exceeds_sponsor_yearly_limit?(storage_fee)
  end

  def exceeds_payer_yearly_limit?(storage_fee)
    return false if payer.payment_configuration&.yearly_ldf_limit.nil?

    payer.payment_logs.for_current_year.sum(&:ldf) + storage_fee > payer.payment_configuration.yearly_ldf_limit.to_f
  end

  def exceeds_sponsor_yearly_limit?(storage_fee)
    sponsor = payer.sponsor
    return false if sponsor.nil?

    payment_conf = sponsor.payment_configuration
    return false if !payment_conf&.covers_ldf || payment_conf&.yearly_ldf_limit.nil?

    paid_amount = SponsoredPaymentLog.for_current_year.where(sponsor_id: sponsor.id).sum(:ldf)
    paid_amount + storage_fee > payment_conf.yearly_ldf_limit.to_f
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
    return false if payer.payment_configuration.ldf_limit.nil?

    tier = @calculator_service.sponsored_tier(payer)
    tier[:price] > 0 && tier[:range].max < resource.total_file_size.to_i
  end
end
