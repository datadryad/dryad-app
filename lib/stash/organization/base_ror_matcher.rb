# frozen_string_literal: true

require 'csv'

module Stash
  module Organization
    class BaseRorMatcher

      attr_reader :perform_updates

      def initialize(perform_updates: true, start_id: nil, end_id: nil, start_created_at: nil, end_created_at: nil)
        @perform_updates = perform_updates
        @end_id = end_id
        @start_id = start_id
        @start_created_at = start_created_at&.to_date
        @end_created_at = end_created_at&.to_date

        @updates_count = 0
        @multiple_ror_found_count = 0
        @no_ror_found_count = 0
        @csv_rows = []
      end

      def perform
        items_to_be_mapped = filter_items

        start_report(items_to_be_mapped.count)
        map_items(items_to_be_mapped)
        end_report
        copy_to_s3
      end

      private

      def filter_items
        items = base_items_query
        items = items.where('id >= ?', @start_id) if @start_id
        items = items.where('id <= ?', @end_id) if @end_id
        items = items.where('created_at >= ?', @start_created_at) if @start_created_at
        items = items.where('created_at <= ?', @end_created_at) if @end_created_at
        items
      end

      def start_report(items_count)
        puts ''
        puts '========================================================================================'
        @text = "Processing #{items_count} records"
        @text += " starting with id: #{@start_id}" if @start_id
        @text += " ending with id: #{@end_id}" if @end_id
        @text += " starting from: #{@start_created_at}" if @start_created_at
        @text += " ending on: #{@end_created_at}" if @end_created_at
        @text += ':'
        puts @text
        initialize_csv_report
      end

      def end_report
        messages = [
          [],
          [@text.gsub('Processing', 'From')],
          [" - Updated: #{@updates_count} records."],
          [" - Multiple RORs found: #{@multiple_ror_found_count} records."],
          [" - No ROR found: #{@no_ror_found_count} records."]
        ]
        update_csv_report(messages)

        puts ''
        messages.each do |message|
          puts message.first
        end
        puts "Report file: #{@report_name}"
      end

      def initialize_csv_report
        filters_text = @text.downcase.gsub(':', '').gsub(' ', '_')
        @report_name = report_file_name(filters_text)
        @report_path = report_file_path(@report_name)

        @csv = CSV.open(@report_path, 'wb') do |csv|
          csv << report_headers
        end
      end

      def update_csv_report(csv_rows)
        @csv = CSV.open(@report_path, 'a+') do |csv|
          csv_rows.each do |row|
            csv << row
          end
        end
      end

      def map_items(items_to_be_mapped)
        index = 0

        items_to_be_mapped.find_each do |item|
          index += 1
          if index % 100 == 0
            sleep 2
            update_csv_report(@csv_rows)
            @csv_rows = []
          end

          handle_item(item, record_name(item), index)
        end
        update_csv_report(@csv_rows)
      end

      def handle_item(item, item_name, index)
        puts ''
        puts "#{index}. Processing record \"#{item_name}\" (id: #{item.id}, created_at: #{item.created_at})"

        if record_ror_id(item).present?
          puts ' - ROR already updated'
          return
        end

        rors = StashEngine::RorOrg.find_by_name_for_auto_matching(item_name)
        case rors.count
        when 0
          @no_ror_found_count += 1
          # Do not add to CSV report, nor log file, as it will increase the file size too much
          # message = 'Could not find ROR'
          # @csv_rows << [item.id, item_name, message]
          # puts " - #{message} for \"#{item_name}\""
        when 1
          connect_to_ror(item, rors.first)
        else
          @multiple_ror_found_count += 1
          message = 'Found multiple RORs'
          @csv_rows << [item.id, item_name, message, rors.map { |ror| ror[:name] }.join("\n"), rors.map { |ror| ror[:id] }.join("\n")]
          puts " - #{message} for \"#{item_name}\""
        end
      end

      def copy_to_s3
        s3_key = "#{Rails.env}/RorMatcher/#{@report_name}"
        puts "Copying to S3: #{s3_key}"
        Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:reports_bucket])
          .put_file(s3_key: s3_key, filename: @report_path)
      ensure
        FileUtils.rm_f(@report_path)
      end

      def report_file_path(report_name)
        @report_file_path ||= File.join(REPORTS_DIR, report_name)
      end

      def base_items_query
        raise NotImplementedError, 'Subclasses must implement base_items_query'
      end

      def record_name(item)
        raise NotImplementedError, 'Subclasses must implement record_name'
      end

      def record_ror_id(item)
        raise NotImplementedError, 'Subclasses must implement record_ror_id'
      end

      def connect_to_ror(affiliation, ror)
        raise NotImplementedError, 'Subclasses must implement connect_to_ror'
      end

      def report_file_name(filters_text)
        raise NotImplementedError, 'Subclasses must implement report_file_name'
      end

      def report_headers
        raise NotImplementedError, 'Subclasses must implement report_headers'
      end
    end
  end
end
