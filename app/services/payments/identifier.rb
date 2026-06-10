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

    def total_dpc
      identifiers.where(payment_id: sponsor.id).count * sponsor.dpc_fee
    end
  end
end
