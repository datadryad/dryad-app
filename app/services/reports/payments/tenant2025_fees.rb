require 'byebug'
require 'csv'

module Reports
  module Payments
    class Tenant2025Fees < Reports::Payments::Base

      def initialize
        super

        @summary_file_name = '2025_fees_tenant_summary.csv'
        @payment_plan = '2025'
      end

      def build_csv_file(time_period:, prefix:, filename:, sc_report_file:)
        sc_report = CSV.parse(File.read(sc_report_file), headers: true)

        CSV.open(filename, 'w') do |csv|
          csv << %w[SponsorName InstitutionName Count]
          sponsor_summary = []
          sponsor_total_count = 0
          StashEngine::Tenant.fees_2025.each do |tenant|
            next if tenant.sponsor

            consortium = tenant.consortium
            consortium.each do |c|
              tenant_item_count = 0
              sc_report.each do |item|
                if item['PaymentID'] == c.id
                  tenant_item_count += 1
                  sponsor_summary << [item['DOI'], c.short_name, item['ApprovalDate']]
                end
              end
              csv << [tenant.short_name, c.short_name, tenant_item_count, '']
              sponsor_total_count += tenant_item_count
            end
            next if sponsor_summary.blank?

            write_sponsor_summary(name: tenant.short_name, file_prefix: prefix, report_period: time_period, table: sponsor_summary,
                                  payment_plan: @payment_plan)
            sponsor_summary = []
            sponsor_total_count = 0
          end
        end
      end
    end
  end
end
