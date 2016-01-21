require 'stash/wrapper'
require 'datacite/mapping'
require_relative '../datacite_extensions'
require_relative '../metadata_mapper'

module Stash
  module Harvester
    module DataciteGeoblacklight

      class Mapper < MetadataMapper
        include Datacite::Mapping

        metadata_mapping 'datacite_geoblacklight'

        def to_index_document(wrapper) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          stash_descriptive = wrapper.stash_descriptive
          datacite_xml = stash_descriptive.find { |elem| Resource.datacite?(elem) }
          resource = Resource.parse_xml(datacite_xml)

          # TODO: how do we deal with the fact we have multiple points/boxes & GB doesn't?
          {
            dc_identifier_s:  wrapper.id_value,
            dc_title_s:       resource.default_title,
            dc_creator_sm:    resource.creator_names,
            dc_type_s:        resource.type,
            dc_description_s: resource.description_text_for(DescriptionType::ABSTRACT),
            dc_subject_sm:    resource.subjects.map(&:value),
            dct_spatial_sm:   resource.geo_location_places,
            georss_box_bbox:  resource.geo_location_boxes[0],
            georss_point_pt:  resource.geo_location_points[0],
            dct_issued_dt:    wrapper.embargo_end_date,
            dc_rights_s:      wrapper.license.name,
            dc_publisher_s:   resource.publisher
          }

          # TODO: do we need to strip nil values or does RSolr take care of that?
        end

      end
    end
  end
end
