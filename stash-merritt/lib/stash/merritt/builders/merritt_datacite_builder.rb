require 'datacite/mapping/datacite_xml_factory'
require 'stash/repo/file_builder'

module Stash
  module Merritt
    module Builders
      class MerrittDataciteBuilder < Stash::Repo::FileBuilder
        attr_reader :factory

        # @param factory [DataciteXMLFactory] the Datacite XML factory
        def initialize(factory)
          super(file_name: 'mrt-datacite.xml')
          @factory = factory
        end

        def build_xml
          factory.build_datacite_xml
        end
      end
    end
  end
end
