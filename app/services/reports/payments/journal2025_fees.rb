require 'byebug'
require 'csv'

module Reports
  module Payments
    class Journal2025Fees < Reports::Payments::Base

      def initialize
        super

        @summary_file_name = '2025_fees_summary.csv'
        @payment_plan = '2025'
      end

      def build_csv_file(time_period:, prefix:, filename:, sc_report_file:)
        sc_report = CSV.parse(File.read(sc_report_file), headers: true)

        CSV.open(filename, 'w') do |csv|
          csv << %w[SponsorName JournalName Count]
          sponsor_summary     = []
          sponsor_total_count = 0
          StashEngine::JournalOrganization.all.each do |org|
            journals = org.journals_sponsored_deep
            journals.each do |j|
              next unless j.payment_plan_type == '2025' && j.top_level_org == org

              journal_item_count = 0
              sc_report.each do |item|
                if item['JournalISSN'] == j.single_issn
                  journal_item_count += 1
                  sponsor_summary << [item['DOI'], j.title, item['ApprovalDate']]
                end
              end
              csv << [org.name, j.title, journal_item_count, '']
              sponsor_total_count += journal_item_count
            end
            next if sponsor_summary.blank?

            write_sponsor_summary(name: org.name, file_prefix: prefix, report_period: time_period, table: sponsor_summary,
                                  payment_plan: @payment_plan)
            sponsor_summary     = []
            sponsor_total_count = 0
          end
        end
      end
    end
  end
end
