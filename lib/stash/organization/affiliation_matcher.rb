# frozen_string_literal: true

require 'csv'

module Stash
  module Organization
    class AffiliationMatcher

      attr_reader :perform_updates

      def initialize(perform_updates: false, start_id: nil, end_id: nil, start_created_at: nil, end_created_at: nil)
        @perform_updates = perform_updates
        @end_id = end_id
        @start_id = start_id
        @start_created_at = start_created_at&.to_date
        @end_created_at = end_created_at&.to_date

        @updates_count = 0
        @multiple_ror_found_count = 0
        @no_ror_found_count = 0
      end

      def perform
        items_to_be_mapped = filter_affiliations
        index = 0

        puts ''
        puts '========================================================================================'
        text = "Processing #{items_to_be_mapped.count} affiliations"
        text += " starting with id: #{@start_id}" if @start_id
        text += " ending with id: #{@end_id}" if @end_id
        text += " starting from: #{@start_created_at}" if @start_created_at
        text += " ending on: #{@end_created_at}" if @end_created_at
        text += ':'
        puts text
        initialize_csv_report(text)

        items_to_be_mapped.find_in_batches(batch_size: 100) do |batch|
          sleep 2
          batch.each do |item|
            messages = []
            puts ''
            puts "#{index += 1}. Processing affiliation \"#{item.long_name}\" (id: #{item.id}, created_at: #{item.created_at})"

            rors = StashEngine::RorOrg.find_by_ror_name(item.long_name, 2)
            case rors.count
            when 0
              @no_ror_found_count += 1
              message = "Could not find ROR"
              messages << [item.id, item.long_name, item.authors.count, message]
              puts " - #{message} for \"#{item.long_name}\""
            when 1
              connect_to_ror(item, rors.first, messages)
            else
              @multiple_ror_found_count += 1
              message = "Found multiple RORs"
              messages << [item.id, item.long_name, item.authors.count, message, rors.map { |ror| ror[:long_name] }.join("\n")]
              puts " - #{message} for \"#{item.long_name}\""
            end
            pp messages
            update_csv_report(messages)
          end
        end

        messages = [
          [text.gsub('Processing', 'From')],
          [" - Updated: #{@updates_count} affiliations."],
          [" - No ROR found: #{@no_ror_found_count} affiliations."],
          [" - Multiple RORs found: #{@multiple_ror_found_count} affiliations."],
        ]
        update_csv_report(messages)

        puts ''
        messages.each do |message|
          puts message.first
        end
        puts "Report file: #{@report_name}"
      end

      private

      def filter_affiliations
        items = StashDatacite::Affiliation.where(ror_id: nil)
        items = items.where('id >= ?', @start_id) if @start_id
        items = items.where('id <= ?', @end_id) if @end_id
        items = items.where('created_at >= ?', @start_created_at) if @start_created_at
        items = items.where('created_at <= ?', @end_created_at) if @end_created_at
        items
      end

      def connect_to_ror(item, ror, messages)
        # puts '------------- connect_to_ror -------------'
        ror_id = ror[:id]

        rep = StashDatacite::Affiliation.find_by(ror_id: ror_id)
        rep ||= StashDatacite::Affiliation.from_ror_id(ror_id: ror_id)
        to_fix = StashDatacite::Affiliation.where(ror_id: nil, long_name: item.long_name)

        if ror[:name] != rep.long_name
          rep.update(long_name: ror[:name]) if perform_updates
          message = 'Updating existing affiliation name with'
          puts " - #{message} \"#{rep.long_name}\" (id: #{rep.id}) with \"#{ror[:name]}\""
          messages << [rep.id, rep.long_name, rep.authors.count, message, ror[:name]]
        end

        message = 'Replacing affiliations with'
        puts " - #{message} name \"#{item.long_name}\" (ids: #{to_fix.ids}) with \"#{ror[:name]}\" (id: #{rep.id || 'new'})"
        messages << [item.id, item.long_name, item.authors.count, message, ror[:name], ror[:id], rep.id]
        @updates_count += 1
        return unless perform_updates

        # updating authors affiliation with new affiliation
        to_fix.each do |aff|
          aff.authors.each do |auth|
            auth.affiliation = rep
          end
          aff.destroy
        end
      end

      def initialize_csv_report(text)
        text = text.downcase.gsub(':', '').gsub(' ', '_')
        @report_name = File.join(REPORTS_DIR, "affiliation_matcher_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{text}.csv")

        @csv = CSV.open(@report_name, 'wb') do |csv|
          csv << ['Affiliation ID', 'Long Name', 'Authors Count', 'Message', 'ROR Name', 'ROR ID', 'New Affiliation ID']
        end
      end

      def update_csv_report(messages)
        @csv = CSV.open(@report_name, 'a+') do |csv|
          messages.each do |row|
            csv << row
          end
        end
      end
    end
  end
end
