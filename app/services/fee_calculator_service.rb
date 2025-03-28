class FeeCalculatorService

  def initialize(type)
    @calculation_type = type
  end

  def calculate(options, for_dataset: false)
    calculator_class.constantize.new(options, for_dataset: for_dataset).call
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
