module Payments
  class Sponsor
    attr_reader :sponsor, :year

    def initialize(sponsor, year: Date.today.year)
      @sponsor = sponsor
      @year = year.to_i
    end

    def identifiers
      sponsor.sponsored_identifiers
        .joins(:process_date)
        .where(process_date: { processing: Date.new(year).all_year })
    end

    def payment_configuration
      sponsor.payment_configuration
    end

    def total_ldf
      @total_ldf ||= sponsor_logs.sum(:ldf)
    end

    def spent_ldf
      @spent_ldf ||= sponsor_logs
        .joins(resource: :identifier).where(identifier: { pub_state: %w[published embargoed retracted] })
        .sum(:ldf)
    end

    def reserved_ldf
      total_ldf - spent_ldf
    end

    def total_dpc
      @total_dpc ||= identifiers.count * dpc_fee
    end

    private

    def sponsor_logs
      logs = SponsoredPaymentLog.for_year(@year).where(sponsor_id: sponsor.id)
      if sponsor.is_a?(StashEngine::JournalOrganization)
        logs.where(payer_type: 'StashEngine::Journal')
      else
        logs.where(payer_type: 'StashEngine::Tenant')
      end
    end

    def dpc_fee
      150
    end
  end
end
