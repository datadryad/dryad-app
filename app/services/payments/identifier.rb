module Payments
  class Identifier
    attr_reader :identifier, :payment_sponsor, :limits_sponsor

    def initialize(id)
      @identifier = StashEngine::Identifier.find(id)
      @payment_sponsor = PayersService.new(@identifier.payer).payment_sponsor
      @limits_sponsor = PayersService.new(@identifier.payer).limits_sponsor
    end

    def total_ldf
      return if payment_sponsor.nil?

      SponsoredPaymentLog
        .where(sponsor_id: payment_sponsor.id)
        .where(resource_id: identifier.resource_ids)
        .sum(:ldf)
    end

    def update_payment_details(payment)
      return if identifier.old_system_valid_payer?
      return if identifier.sponsored?
      return if identifier.waiver?

      PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: identifier)
    end
  end
end
