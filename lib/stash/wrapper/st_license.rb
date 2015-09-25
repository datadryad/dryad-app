require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Mapping class for `<st:license>`
    class License
      include ::XML::Mapping

      text_node :name, 'name'
      uri_node :uri, 'uri'

      # Creates a new {License} object
      # @param name [String] The license name
      # @param uri [URI] The license URI
      def initialize(name:, uri:)
        self.name = name
        self.uri = uri
      end
    end

    class License
      # Convenience instance for the [CC-BY](https://creativecommons.org/licenses/by/4.0/legalcode) license
      CC_BY = License.new(
        name: 'Creative Commons Attribution 4.0 International (CC-BY)',
        uri: URI('https://creativecommons.org/licenses/by/4.0/legalcode')
      )
    end
  end
end
