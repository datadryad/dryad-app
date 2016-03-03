require 'stash/wrapper'
require 'datacite/mapping'
require_relative '../datacite_extensions'
require_relative '../metadata_mapper'

module Stash
  module Indexer
    module DataciteDefault

      class Mapper < MetadataMapper
        include Datacite::Mapping

        metadata_mapping 'datacite_default'

        def initialize(*opts)
          super
        end

        def to_index_document(wrapper) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          stash_descriptive = wrapper.stash_descriptive
          datacite_xml = stash_descriptive.find { |elem| Resource.datacite?(elem) }
          resource = Resource.parse_xml(datacite_xml)

          {
            id_s:                   wrapper.id_value,
            title_s:                resource.default_title,
            creator_sm:             resource.creator_names,
            creator_affiliation_sm: resource.creator_affiliations.map { |a| a.join(', ') },
            type_s:                 resource.type,
            abstract_s:             resource.description_text_for(DescriptionType::ABSTRACT),
            funder_name_s:          resource.funder_name,
            funder_id_s:            resource.funder_id_value,
            grant_number_s:         resource.grant_number,
            keywords_sm:            resource.subjects.map(&:value),
            methods_s:              resource.description_text_for(DescriptionType::METHODS),
            usage_notes_s:          resource.usage_notes,
            related_identifier_sm:  resource.related_identifiers.map(&:value),
            place_sm:               resource.geo_location_places,
            box_bboxm:              resource.geo_location_boxes,
            point_ptm:              resource.geo_location_points,
            file_names:             wrapper.file_names,
            embargo_end_date:       wrapper.embargo_end_date,
            publisher:              resource.publisher,
            pub_year:               resource.publication_year
          }

          # TODO: do we need to strip nil values or does RSolr take care of that?
        end

      end
    end
  end
end
