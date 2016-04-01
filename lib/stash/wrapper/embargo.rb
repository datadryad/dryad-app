require 'xml/mapping_extensions'
require_relative 'embargo_type'

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
        self.type = type
        self.period = period
        self.start_date = start_date
        self.end_date = end_date
      end

      # Creates a new `Embargo` instance of type {EmbargoType::NONE} with the current date as start and end.
      # @return [Embargo]
      def self.none
        today = Date.today
        new(type: EmbargoType::NONE, period: EmbargoType::NONE.value, start_date: today, end_date: today)
      end
    end

  end
end
