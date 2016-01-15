require 'stash/wrapper'
require 'datacite/mapping'
require_relative 'datacite_extensions'
require_relative '../metadata_mapper'

module Stash
  module Harvester
    module DataciteDefault
      include Datacite::Mapping

      class Mapper < MetadataMapper
        metadata_mapping 'datacite_default'

        def to_index_document(wrapper) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          stash_descriptive = wrapper.stash_descriptive
          datacite_xml = stash_descriptive.find { |elem| Resource.datacite?(elem) }
          resource = Resource.parse_xml(datacite_xml)

          # TODO: write up a real crosswalk & make sure we have all fields
          {
            id_s:                   wrapper.id_value,
            dc_title_s:             resource.default_title,
            dc_creator_sm:          resource.creator_names,
            creator_affiliation_sm: resource.creator_affiliations.map { |a| a.join(', ') },
            dc_type_s:              resource.type,
            dc_description_s:       resource.description_text_for(DescriptionType::ABSTRACT),
            methods_s:              resource.description_text_for(DescriptionType::METHODS),
            usage_notes_s:          resource.usage_notes,
            dct_place_sm:           resource.geo_location_places,
            georss_box_bboxm:       resource.geo_location_boxes,
            georss_point_ptm:       resource.geo_location_points,
            embargo_type:           wrapper.embargo_type,
            embargo_end_date:       wrapper.embargo_end_date,
            dc_publisher:           resource.publisher,
            pub_year:               resource.publication_year
          }

          # TODO: do we need to strip nil values or does RSolr take care of that?
        end

      end
    end
  end
end
