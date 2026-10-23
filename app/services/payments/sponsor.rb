module Payments
  class Sponsor
    attr_reader :sponsor, :year, :plan

    def initialize(sponsor, year: Date.today.year, plan: '2025')
      @sponsor = sponsor
      @year = year.to_i
      @plan = plan
    end

    def identifiers
      return @identifiers if @identifiers

      ids = StashEngine::Identifier.where.not(pub_state: 'withdrawn')
        .where(id: sponsor.dpcs_sponsored.where(payment_plan: plan).pluck(:identifier_id))
      ids = ids.where('YEAR(publication_date) = ?', year) if year != Date.today.year.to_i
      @identifiers = ids
    end

    def payment_configuration
      sponsor.payment_configuration
    end

    def total_ldf
      @total_ldf = sponsor_logs.sum(:ldf)
    end

    def spent_ldf
      @spent_ldf ||= sponsor_logs.where.not(identifier: { publication_date: nil }).sum(:ldf)
    end

    def reserved_ldf
      @reserved_ldf = sponsor_logs.where(identifier: { pub_state: 'unpublished' }).sum(:ldf)
    end

    def sponsor_logs
      @sponsor_logs ||= sponsor.payment_logs.joins(resource: :identifier).where(identifier: { id: identifiers.pluck(:id) })
    end
  end
end
