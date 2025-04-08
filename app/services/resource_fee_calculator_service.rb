class ResourceFeeCalculatorService

  def initialize(resource)
    @resource = resource
  end

  def calculate(options)
    FeeCalculatorService.new(type).calculate(options, resource: @resource)
  end

  private

  def type
    ident = @resource.identifier
    return 'waiver' if ident.payment_type == 'waiver'

    if ident.institution_will_pay?
      'institution'
    elsif ident.journal&.will_pay? || ident.funder_will_pay?
      'publisher'
    else
      'individual'
    end
  end
end
