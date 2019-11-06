require 'xml/mapping_extensions'
require 'stash/wrapper/identifier_type'

module Stash
  module Wrapper

    # Mapping class for `<st:identifier>`
    class Identifier
      include ::XML::Mapping
      typesafe_enum_node :type, '@type', class: IdentifierType, default_value: nil
      text_node :value, '.', default_value: nil

      # Creates a new {Identifier}
      def initialize(type:, value:)
        raise ArgumentError, "Identifier type does not appear to be an IdentifierType: #{type || 'nil'}" unless type.is_a?(IdentifierType)
        raise ArgumentError, "Identifier value does not appear to be a non-empty string: #{value.inspect}" if value.to_s.strip.empty?
        self.type = type
        self.value = value
      end

      def formatted
        type.format(value)
      end
    end

  end
end
