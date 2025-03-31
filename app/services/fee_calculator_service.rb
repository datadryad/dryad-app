class FeeCalculatorService

  def initialize(type)
    @calculation_type = type
  end

  def calculate(options, resource: nil)
    calculator_class.constantize.new(options, resource: resource).call
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
    else
      raise NotImplementedError, 'Invalid calculator type'
    end
  end
end
