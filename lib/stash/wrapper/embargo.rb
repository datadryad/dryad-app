require 'xml/mapping_extensions'
require 'stash/wrapper/embargo_type'

module Stash
  module Wrapper

    # Mapping class for `<st:embargo>`
    class Embargo
      include ::XML::Mapping

      typesafe_enum_node :type, 'type', class: EmbargoType
      text_node :period, 'period'
      date_node :start_date, 'start', zulu: true
      date_node :end_date, 'end', zulu: true

      # Creates a new {Embargo} object
      # @param type [EmbargoType] The embargo type
      # @param period [String] The embargo period
      # @param start_date [Date] The embargo start date
      # @param end_date [Date] The embargo end date
      def initialize(type:, period:, start_date:, end_date:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        fail ArgumentError, "Specified type does not appear to be an EmbargoType: #{type || 'nil'}" unless type && type.is_a?(EmbargoType)
        fail ArgumentError, "Specified embargo period does not appear to be a non-empty string: #{period.inspect}" if period.to_s.strip.empty?
        fail ArgumentError, "Specified start date does not appear to be a date: #{start_date || 'nil'}" unless start_date && start_date.respond_to?(:iso8601)
        fail ArgumentError, "Specified end date does not appear to be a date: #{end_date || 'nil'}" unless end_date && end_date.respond_to?(:iso8601)

        self.type = type
        self.period = period.to_s
        self.start_date, self.end_date = valid_range(start_date, end_date)
      end

      # Creates a new `Embargo` instance of type {EmbargoType::NONE} with the current date as start and end.
      # @return [Embargo]
      def self.none
        today = Date.today
        new(type: EmbargoType::NONE, period: EmbargoType::NONE.value, start_date: today, end_date: today)
      end

      private

      def valid_range(start_date, end_date)
        if start_date > end_date
          fail RangeError, "start_date #{start_date} must be <= end_date #{end_date}"
        else
          [start_date.to_date, end_date.to_date]
        end
      end
    end
  end
end
