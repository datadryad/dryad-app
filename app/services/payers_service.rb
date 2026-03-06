class PayersService
  attr_reader :payer

  def initialize(payer)
    @payer = payer
  end

  def is_2025_payer?
    payment_sponsor.payment_configuration&.payment_plan.to_s == '2025'
  end

  def payment_sponsor
    payer.payment_sponsor
  rescue StandardError
    payer
  end
end
