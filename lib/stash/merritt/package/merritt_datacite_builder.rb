require 'stash/repo/util/file_builder'

module Stash
  module Merritt
    module Package
      class MerrittDataciteBuilder < Stash::Repo::Util::FileBuilder
        attr_reader :factory

        # @param factory [DataciteXMLFactory] the Datacite XML factory
        def initialize(factory)
          @factory = factory
        end

        def file_name
          'mrt-datacite.xml'
        end

        def contents
          factory.build_datacite_xml(datacite_3: true)
        end
      end
    end
  end
end
