# frozen_string_literal: true

require 'csv'

module Stash
  module Organization
    class AffiliationRorMatcher < BaseRorMatcher

      private

      def connect_to_ror(item, ror)
        # puts '------------- connect_to_ror -------------'
        ror_id = ror[:id]

        rep = StashDatacite::Affiliation.find_by(ror_id: ror_id)
        rep ||= StashDatacite::Affiliation.from_ror_id(ror_id: ror_id)
        to_fix = StashDatacite::Affiliation.where(ror_id: nil, long_name: item.long_name)

        update_affiliation_name(rep, ror)

        message = 'Replacing affiliations with'
        puts " - #{message} name \"#{item.long_name}\" (ids: #{to_fix.ids}) with \"#{ror[:name]}\" (id: #{rep.id || 'new'})"
        @csv_rows << [item.id, item.long_name, item.authors.count, message, ror[:name], ror[:id], rep.id]
        @updates_count += to_fix.count
        return unless perform_updates

        to_fix.each do |aff|
          # updating authors affiliation with new affiliation
          aff.authors.each do |author|
            author.affiliation = rep
          end
          aff.destroy
        end
      end

      def update_affiliation_name(rep, ror)
        return if ror[:name] == rep.long_name

        rep.update(long_name: ror[:name]) if perform_updates
        message = 'Updating existing affiliation name'
        puts " - #{message} \"#{rep.long_name}\" (id: #{rep.id}) with \"#{ror[:name]}\""
        @csv_rows << [rep.id, rep.long_name, rep.authors.count, message, ror[:name]]
      end

      def record_name(item)
        item.long_name
      end

      def record_ror_id(item)
        item.ror_id
      end

      def base_items_query
        StashDatacite::Affiliation.where(ror_id: nil)
      end

      def report_file_name(filters_text)
        @report_file_name ||= "affiliation_ror_matcher_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{filters_text}.csv"
      end

      def report_headers
        ['Affiliation ID', 'Long Name', 'Authors Count', 'Message', 'ROR Name', 'ROR ID', 'New Affiliation ID']
      end
    end
  end
end
