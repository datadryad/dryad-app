require 'csv'

# Reports::Emails::AbandonedEmailsByType.new.call
module Reports
  module Emails
    class AbandonedEmailsByType
      attr_reader :start_date, :end_date

      def initialize(start_date: nil, end_date: nil)
        @start_date = start_date&.to_date
        @end_date = end_date&.to_date
        @file_name = 'reminder_emails_by_type.csv'
      end

      def call
        rows = StashEngine::CurationActivity
        rows = rows.where('created_at >= ?', start_date) if start_date
        rows = rows.where('created_at <= ?', end_date) if end_date

        rows = rows.where(notes_condition)
          .select('DATE(created_at) AS day', 'note', 'COUNT(*) AS note_count')
          .group('DATE(created_at)', 'note')
          .order('day ASC, note_count DESC')

        CSV.open(File.join(REPORTS_DIR, @file_name), 'w') do |csv|
          csv << header
          rows.to_a.group_by(&:day).each do |date, row|
            csv << ([date] + parsed_row(row))
          end
        end
        true
      end

      private

      def notes_condition
        columns.values.flatten.map { |text| "note like '#{text}'" }.join(' OR ')
      end

      def header
        [Date] + columns.keys
      end

      def columns
        {
          'In progress - 1 day' => ['1 days in_progress_reminder CRON - reminded submitter that this item is still `in_progress`'],
          'In progress - 3 days' => [
            'in_progress_reminder CRON - reminded submitter that this item is still `in_progress`',
            '3 days in_progress_reminder CRON - reminded submitter that this item is still `in_progress`'
          ],
          'In progress - monthly' => ['in_progress_deletion_notice - reminded submitter that this item is still `in_progress`'],
          'Action required - 2 weeks' => ['CRON: mailed action required reminder 1'],
          'Action required - monthly' => ['action_required_deletion_notice - reminded submitter that this item is still `action_required`'],
          'Peer review - monthly' => ['peer_review_deletion_notice - reminded submitter that this item is still `peer_review`'],
          'Withdrawn notice' => ['withdrawn_email_notice - notification that this item was set to `withdrawn`'],
          'Final withdrawn notice' => ['final_withdrawn_email_notice - reminded submitter that this item is still `withdrawn`']
        }
      end

      def parsed_row(row)
        res = []
        return res if row.blank?

        agg = row.group_by(&:note)
        columns.each_value do |notes|
          res << notes.map do |a|
            agg[a]&.sum(&:note_count).to_i
          end.sum
        end
        res
      end
    end
  end
end
