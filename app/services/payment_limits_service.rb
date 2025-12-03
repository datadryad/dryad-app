class PaymentLimitsService
  attr_reader :resource, :payer

  def initialize(resource, payer)
    @resource = resource
    @payer = payer
  end

  def payment_allowed?
    !limits_exceeded?
  end

  def limits_exceeded?
    return true if payer.nil?
    return false unless PayersService.new(payer).is_2025_payer?
    return false if payer.payment_configuration.yearly_ldf_limit.nil?

    exceeds_yearly_ldf_limit?
  end

  private

  def exceeds_yearly_ldf_limit?
    resource_fees = calculate_fees
    return false if resource_fees[:storage_fee].to_f.zero?

    payer.payment_logs.for_current_year.sum(&:ldf) + resource_fees[:storage_fee].to_f > payer.payment_configuration.yearly_ldf_limit.to_f
  end

  def calculate_fees
    payer_type = case payer.class.name
                 when 'StashEngine::Funder', 'StashEngine::Journal'
                   'publisher'
                 when 'StashEngine::Tenant'
                   'institution'
                 end

    FeeCalculatorService.new(payer_type).calculate({}, resource: resource, payer_record: payer)
  end
end
