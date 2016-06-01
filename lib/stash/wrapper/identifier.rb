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
        fail ArgumentError, "Specified type does not appear to be an IdentifierType: #{type || 'nil'}" unless type && type.is_a?(IdentifierType)
        fail ArgumentError, "Specified value does not appear to be a non-empty string: #{value.inspect}" if value.to_s.strip.empty?
        self.type = type
        self.value = value
      end
    end

  end
end
