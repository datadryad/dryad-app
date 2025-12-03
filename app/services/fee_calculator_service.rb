class FeeCalculatorService

  def initialize(type)
    @calculation_type = type
  end

  def calculate(options, resource: nil)
    calculator_class.constantize.new(options, resource: resource).call
  end

  def storage_fee_tier(resource: nil)
    calculator_class.constantize.new({}, resource: resource).storage_fee_tier
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
