class ResourceFeeCalculatorService
  attr_reader :resource, :identifier, :payer_record

  def initialize(resource, payer_record = nil)
    @resource = resource
    @payer_record = payer_record
  end

  def calculate(options)
    FeeCalculatorService.new(type).calculate(options, resource: resource, payer_record: payer_record)
  rescue ActionController::BadRequest => e
    { error: true, message: e.message, old_payment_system: e.message == OLD_PAYMENT_SYSTEM_MESSAGE }
  end

  def storage_fee_tier
    FeeCalculatorService.new(type).storage_fee_tier(resource: resource)
  end

  def sponsored_tier
    FeeCalculatorService.new(type).sponsored_tier(resource, payer_record)
  end

  private

  def type
    ident = resource.identifier
    return 'waiver' if ident.waiver?
    return 'individual' if !ident.old_system_valid_payer? && !ident.payer_2025? && ident.payment_type.blank?

    # rubocop:disable Lint/DuplicateBranch
    if ident.funder_will_pay?
      'publisher'
    elsif ident.institution_will_pay?
      'institution'
    elsif ident.journal_will_pay?
      'publisher'
    else
      'individual'
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
