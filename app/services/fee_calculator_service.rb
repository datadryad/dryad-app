class FeeCalculatorService

  def initialize(type)
    @calculation_type = type
  end

  def calculate(options, resource: nil, payer_record: nil)
    calculator_class.constantize.new(options, resource: resource, payer_record: payer_record).call
  end

  def storage_fee_tier(resource: nil)
    calculator_class.constantize.new({}, resource: resource).storage_fee_tier
  end

  def ldf_sponsored_amount(resource: nil, payer: nil)
    calculator_class.constantize.new({}, resource: resource, payer_record: payer).ldf_sponsored_amount
  end

  def sponsored_tier(payer)
    calculator_class.constantize.new({})
      .get_tier_by_value(
        FeeCalculator::BaseService::ESTIMATED_FILES_SIZE,
        payer.payment_configuration.ldf_limit
      )
  end

  private

  def calculator_class
    case @calculation_type
    when 'institution'
      'FeeCalculator::InstitutionService'
    when 'publisher'
      'FeeCalculator::PublisherService'
    when 'individual'
      'FeeCalculator::IndividualService'
    when 'waiver'
      'FeeCalculator::WaiverService'
    else
      raise NotImplementedError, 'Invalid calculator type'
    end
  end
end
