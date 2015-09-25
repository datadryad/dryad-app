require 'xml/mapping'
require 'xml/mapping_extensions'
require_relative 'st_identifier_type_node'

module Stash
  module Wrapper

    # Mapping class for `<st:identifier>`
    class Identifier
      include ::XML::Mapping
      identifier_type_node :type, '@type', default_value: nil
      text_node :value, '.', default_value: nil

      # Creates a new {Identifier}
      def initialize(type:, value:)
        self.type = type
        self.value = value
      end
    end

  end
end
