# frozen_string_literal: true

require 'csv'

module Stash
  module Organization
    class ContributorRorMatcher < BaseRorMatcher

      private

      def connect_to_ror(item, ror)
        # puts '------------- connect_to_ror -------------'
        ror_id = ror[:id]
        message = 'Updating contributor with'
        puts " - #{message} name \"#{item.contributor_name}\" (ids: #{item.id}) with \"#{ror[:name]}\" (ror_id: #{ror_id})"
        @csv_rows << [item.id, item.contributor_name, message, ror[:name], ror[:id]]
        @updates_count += 1

        return unless perform_updates

        item.update(contributor_name: ror[:name], identifier_type: 'ror', name_identifier_id: ror_id)
      end

      def record_name(item)
        item.contributor_name
      end

      def record_ror_id(item)
        item.name_identifier_id
      end

      def base_items_query
        StashDatacite::Contributor.where(name_identifier_id: [nil, ''], identifier_type: ['ror', nil])
      end

      def report_file_name(filters_text)
        File.join(REPORTS_DIR, "contributor_ror_matcher_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{filters_text}.csv")
      end

      def report_headers
        ['Contributor ID', 'Contributor Name', 'Message', 'ROR Name', 'ROR ID']
      end
    end
  end
end
