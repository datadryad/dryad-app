require 'datacite/mapping/datacite_xml_factory'
require 'stash/repo/file_builder'

module Stash
  module Merritt
    module Builders
      class MerrittDataciteBuilder < Stash::Repo::ValidatingXMLBuilder

        class << self
          def dc4_schema
            @dc4_schema ||= begin
              schema_file = "#{File.dirname(__FILE__)}/schemas/datacite/metadata.xsd"
              Nokogiri::XML::Schema(File.open(schema_file))
            end
          end
        end

        attr_reader :factory

        # @param factory [DataciteXMLFactory] the Datacite XML factory
        def initialize(factory)
          super(file_name: 'mrt-datacite.xml')
          @factory = factory
        end

        def build_xml
          dc4_resource.write_xml
        end

        def schema
          MerrittDataciteBuilder.dc4_schema
        end

        private

        def dc4_resource
          @dc4_resource ||= factory.build_resource
        end
      end
    end
  end
end
