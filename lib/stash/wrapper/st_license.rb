require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Dataset license.
    class License
      include ::XML::Mapping
      text_node :name, 'name'
      uri_node :uri, 'uri'

      def initialize(name:, uri:)
        self.name = name
        self.uri = uri
      end
    end

    class License
      CC_BY = License.new(
          name: 'Creative Commons Attribution 4.0 International (CC-BY)',
          uri: URI('https://creativecommons.org/licenses/by/4.0/legalcode')
      )
    end
  end
end
