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
      # @param uri [URI, String] The license URI
      # @raise [URI::InvalidURIError] if `uri` is a string that is not a valid URI
      def initialize(name:, uri:)
        raise ArgumentError, "License name does not appear to be a non-empty string: #{name.inspect}" if name.to_s.strip.empty?
        raise ArgumentError, 'No uri provided' unless uri
        self.name = name
        self.uri = ::XML::MappingExtensions.to_uri(uri)
      end
    end

    class License
      # Convenience instance for the [CC-BY](https://creativecommons.org/licenses/by/4.0/) license
      CC_BY = License.new(
        name: 'Creative Commons Attribution 4.0 International (CC BY 4.0)',
        uri: URI('https://creativecommons.org/licenses/by/4.0/')
      )

      # Convenience instance for the [CC0](https://creativecommons.org/publicdomain/zero/1.0/)
      # public domain declaration
      CC_ZERO = License.new(
        name: 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication',
        uri: URI('https://creativecommons.org/publicdomain/zero/1.0/')
      )
    end
  end
end
