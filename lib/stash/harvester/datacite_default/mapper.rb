require 'stash/wrapper'
require 'datacite/mapping'
require_relative '../metadata_mapper'

module Stash
  module Harvester
    module DataciteDefault
      class Mapper < MetadataMapper
        metadata_mapping 'datacite_default'

        def to_index_document(wrapped_metadata)
          stash_descriptive = wrapped_metadata.stash_descriptive
          datacite_xml = stash_descriptive.find { |elem| datacite?(elem) }
          resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)
          resource.write_xml
        end

        private

        # TODO: move this to Datacite::Mapping?
        def datacite?(elem)
          elem.name == 'resource' && elem.namespace == 'http://datacite.org/schema/kernel-3'
        end

      end
    end
  end
end
