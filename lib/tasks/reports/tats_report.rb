# :nocov:
require 'csv'

module Tasks
  module Reports
    class TatsReport
      include StashEngine::ApplicationHelper

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
          .includes(curation_activities: { user: :roles }, latest_resource: [:curator, :tenant, { journal: :sponsor }])

        CSV.open(File.join(Rails.root.join('reports'), @report_name), 'wb') do |csv|
          csv << csv_header
          items.each do |ident|
            add_identifier_to_csv csv, ident
          end
        end
        true
      end

      private

      def add_identifier_to_csv(csv, ident)
        service = TimeInStatus.new(identifier: ident, return_in: :days)
        queued_time = service.time_in_status %w[queued]
        curation_time = service.time_in_status %w[curation], include_statuses: %w[in_progress], action_taken_by: :dryad
        aar_time = service.time_in_status %w[action_required], include_statuses: %w[in_progress], action_taken_by: :author
        total_time = (queued_time + curation_time + aar_time).round(2)

        csv << [
          ident.id,
          ident.to_s,
          ident.latest_resource.title,
          filesize(ident.storage_size), ident.storage_size,
          ident.latest_resource.tenant&.short_name,
          ident.journal&.title,
          ident.journal&.sponsor&.name,
          ident.most_recent_curator&.name,
          queued_time, (queued_time * 100 / total_time.to_f).round(2),
          curation_time, (curation_time * 100 / total_time.to_f).round(2),
          aar_time, (aar_time * 100 / total_time.to_f).round(2),
          total_time
        ]
      end

      def csv_header
        [
          'ID', 'DOI', 'Title', 'Readable Size', 'Size', 'Institution Partner', 'Journal', 'Journal Sponsor', 'Curator',
          'Time in queue (Queued)', 'Time in queue (%)',
          'Time with curator (Curation)', 'Time with curator (%)',
          'Time with author (AAR)', 'Time with author (%)',
          'Time from submission to publication'
        ]
      end
    end
  end
end
# :nocov:
