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
      def initialize(type:, period:, start_date:, end_date:)
        self.type = valid_type(type)
        self.period = valid_period(period)
        self.start_date, self.end_date = valid_range(start_date, end_date)
      end

      # Creates a new `Embargo` instance of type {EmbargoType::NONE} with the current date as start and end.
      # @return [Embargo]
      def self.none
        today = Date.today
        new(type: EmbargoType::NONE, period: EmbargoType::NONE.value, start_date: today, end_date: today)
      end

      private

      def valid_type(type)
        return type if type.is_a?(EmbargoType)
        raise ArgumentError, "Specified type does not appear to be an EmbargoType: #{type || 'nil'}"
      end

      def valid_period(period)
        period_str = period.to_s
        return period_str unless period_str.strip.empty?
        raise ArgumentError, "Specified embargo period does not appear to be a non-empty string: #{period.inspect}"
      end

      def valid_range(start_date, end_date)
        sd = valid_date(start_date)
        ed = valid_date(end_date)
        raise RangeError, "start_date #{sd} must be <= end_date #{ed}" if sd > ed
        [sd.to_date, ed.to_date]
      end

      def valid_date(date)
        return date if date && date.respond_to?(:iso8601)
        raise ArgumentError, "Specified date does not appear to be a date: #{date || 'nil'}"
      end
    end
  end
end
