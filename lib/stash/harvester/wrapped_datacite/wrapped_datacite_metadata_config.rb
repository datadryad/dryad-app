require 'stash/wrapper'

module Stash
  module Harvester
    module WrappedDatacite
      class WrappedDataciteMetadataConfig < MetadataConfig

        def initialize(**_opts)
        end

        # TODO: Should this assume it's always already extracted from the wrapper?
        def to_solr_hash(metadata_xml)
          descriptive = metadata_xml.stash_descriptive
          descriptive[0]
        end

      end
    end
  end
end
