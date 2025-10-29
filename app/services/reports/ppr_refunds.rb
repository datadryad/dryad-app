require 'csv'

# run from console: Reports::PprRefunds.new.generate
module Reports
  class PprRefunds
    def initialize
      @filename = "ppr_refunds_summary-#{Date.today}.csv"
    end

    def generate(time_period: '2025-05-06'.to_date.beginning_of_day..'2025-08-28'.to_date.end_of_day)
      CSV.open(File.join(REPORTS_DIR, @filename), 'w') do |csv|
        csv << ['DOI', 'Status', 'Paid Amount', 'Paid With', 'Stripe link']
        StashEngine::Identifier
          .joins(:payments)
          .where(payments: { created_at: time_period })
          .where(payment_type: 'stripe')
          .where.not(pub_state: 'published')
          .distinct
          .each do |identifier|

          payments = identifier.payments.paid

          next if payments.none?
          next if payments.ppr_paid.exists?
          next unless identifier.curation_activities.where(status: 'peer_review').exists?

          csv << [
            identifier.identifier,
            identifier.latest_resource.current_curation_status,
            payments.map(&:amount).join("\n"),
            payments.map(&:paid_with).join("\n"),
            payments.map(&:payment_link).join("\n")
          ]
        end
      end

      true
    end
  end
end
