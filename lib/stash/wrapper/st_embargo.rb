require 'xml/mapping'
require 'xml/mapping_extensions'

require_relative 'st_embargo_type_node'

module Stash
  module Wrapper

    # Dataset embargo.
    class Embargo
      include ::XML::Mapping
      embargo_type_node :type, 'type'
      text_node :period, 'period'
      date_node :start_date, 'start', zulu: true
      date_node :end_date, 'end', zulu: true

      def initialize(type:, period:, start_date:, end_date:)
        self.type = type
        self.period = period
        self.start_date = start_date
        self.end_date = end_date
      end
    end

  end
end
