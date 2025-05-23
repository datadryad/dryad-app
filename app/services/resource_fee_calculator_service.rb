class ResourceFeeCalculatorService
  attr_reader :resource, :identifier

  def initialize(resource)
    @resource = resource
  end

  def calculate(options)
    FeeCalculatorService.new(type).calculate(options, resource: resource)
  rescue ActionController::BadRequest => e
    { error: true, message: e.message, old_payment_system: e.message == OLD_PAYMENT_SYSTEM_MESSAGE }
  end

  private

  def type
    ident = resource.identifier
    return 'waiver' if ident.waiver?

    if ident.institution_will_pay?
      'institution'
    elsif ident.journal&.will_pay? || ident.funder_will_pay?
      'publisher'
    else
      'individual'
    end
  end
end
