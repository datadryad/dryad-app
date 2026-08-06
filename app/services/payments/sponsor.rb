module Payments
  class Sponsor
    attr_reader :sponsor, :year

    def initialize(sponsor, year: Date.today.year)
      @sponsor = sponsor
      @year = year.to_i
    end

    def identifiers
      return @identifiers if @identifiers

      ids = sponsor.sponsored_identifiers.joins(:process_date)
      ids = if sponsor.is_a?(StashEngine::JournalOrganization) || sponsor.is_a?(StashEngine::Journal)
              ids.where({ publication_date: [Date.new(year).all_year, nil, ''] })
            else
              ids.where(process_date: { processing: Date.new(year).all_year })
            end
      @identifiers = ids
      ids
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
      @total_dpc ||= identifiers.where(pub_state: %w[published embargoed retracted]).count * dpc_fee
    end

    # private

    def sponsor_logs
      return @sponsor_logs if @sponsor_logs

      logs = SponsoredPaymentLog.joins(:resource)
        .where(resource: { identifier_id: identifiers.pluck(:id) })
      logs = if sponsor.is_a?(StashEngine::JournalOrganization)
               logs.where(sponsor_id: sponsor.id, payer_type: 'StashEngine::Journal')
             elsif sponsor.is_a?(StashEngine::Journal)
               logs.where(payer_id: sponsor.id, payer_type: 'StashEngine::Journal')
             else
               logs.where(sponsor_id: sponsor.id, payer_type: 'StashEngine::Tenant')
             end
      @sponsor_logs = logs
      logs
    end

    def dpc_fee
      150
    end
  end
end
