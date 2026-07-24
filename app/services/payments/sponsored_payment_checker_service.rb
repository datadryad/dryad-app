module Payments
  class SponsoredPaymentCheckerService
    def self.check
      StashEngine::Identifier
        .joins(:process_date)
        .where(process_date: { processing: ['2026-01-01'.to_datetime.beginning_of_day..] })
        .where(last_invoiced_file_size: nil)
        .where.not(payment_type: ['stripe', 'unknown', '', nil])
        .order(id: :desc)
        .reject{|i| i.latest_resource.last_curation_activity.status.in?(['peer_review', 'in_progress', 'withdrawn'])}
        .select{|i| i.sponsored_payment_logs.none?}
        .select{|a| a.latest_resource.total_file_size.to_i > 10_000_000_000}
        .select{|i|
          (PayersService.new(i.payer).sponsored_limits && PayersService.new(i.payer).sponsored_limits.covers_ldf?) ||
            PayersService.new(i.payer).payment_sponsor&.payment_configuration&.covers_ldf? }
        .map(&:id)
    end
  end
end
