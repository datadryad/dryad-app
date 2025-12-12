# :nocov:
require 'csv'

module Tasks
  module Reports
    class TatsReport
      attr_reader :start_time, :end_time

      def initialize(year:, month:)
        @start_time = "#{year}-#{month}-1".to_datetime.beginning_of_month
        @end_time = "#{year}-#{month}-1".to_datetime.end_of_month

        @report_name = "Curation-time-report-for_#{month}-#{year}_#{Time.now.strftime('%Y-%m-%d')}.csv"
      end

      def call
        items = StashEngine::Identifier
                  .joins(:process_date)
                  .where(pub_state: 'published', process_date: { approved: start_time..end_time })
                  .includes(:curation_activities, latest_resource: [:curator, :tenant, journal: :sponsor])

        CSV.open(File.join(Rails.root.join('reports'), @report_name), 'wb') do |csv|
          csv << csv_header
          items.each do |ident|
            service = TimeInStatus.new(identifier: ident, return_in: :days)
            curation_time = service.time_in_status %w[curation]
            aar_time = service.time_in_status %w[action_required]

            csv << [
              ident.id,
              ident.to_s,
              ident.latest_resource.title,
              ident.storage_size,
              ident.latest_resource.tenant&.short_name,
              ident.journal&.title,
              ident.journal&.sponsor&.name,
              ident.most_recent_curator&.name,
              curation_time,
              aar_time,
              (curation_time + aar_time).round(2),
            ]
          end
        end
        true
      end

      private

      def csv_header
        [
          'ID', 'DOI', 'Title', 'Size', 'Dryad Partner', 'Journal', 'Journal Sponsor', 'Curator',
          'Time with curator', 'Time with submitter', 'Time from submission to publication'
        ]
      end
    end
  end
end
# :nocov:
