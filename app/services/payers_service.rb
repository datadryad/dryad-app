class PayersService
  attr_reader :payer

  def initialize(payer)
    @payer = payer
  end

  def is_2025_payer?
    payer.payment_configuration&.payment_plan.to_s == '2025'
  end

end
