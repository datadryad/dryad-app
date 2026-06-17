module Payments
  class Sponsor
    attr_reader :sponsor, :year

    def initialize(sponsor, year: Date.today.year)
      @sponsor = sponsor
      @year = year.to_i
    end

    def identifiers
      sponsor.sponsored_identifiers
        .joins(resources: :process_date)
        .where(process_date: { queued: Date.new(year).all_year })
        .or(
          sponsor.sponsored_identifiers
            .joins(resources: :process_date)
            .where(process_date: { peer_review: Date.new(year).all_year })
        )
    end

    def payment_configuration
      sponsor.payment_configuration
    end

    def total_ldf
      SponsoredPaymentLog.for_year(@year)
        .where(sponsor_id: sponsor.id).sum(:ldf)
    end

    def total_dpc
      identifiers.where(payment_id: sponsor.id).count * dpc_fee
    end

    private

    def dpc_fee
      150
    end
  end
end
