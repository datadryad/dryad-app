class FeeCalculatorService

  def initialize(type)
    @calculation_type = type
  end

  def calculate(options, for_dataset: false)
    FeeCalculator::InstitutionService.new(options, for_dataset: ).call
  end
end
