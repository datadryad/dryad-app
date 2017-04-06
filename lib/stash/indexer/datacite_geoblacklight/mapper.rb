require 'stash/wrapper'
require 'datacite/mapping'
require 'stash/indexer/datacite_extensions'
require 'stash/indexer/metadata_mapper'

module Stash
  module Indexer
    module DataciteGeoblacklight

      class Mapper < MetadataMapper
        include Datacite::Mapping

        metadata_mapping 'datacite_geoblacklight'

        def initialize(*opts)
          super
        end

        def to_index_document(wrapper) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          stash_descriptive = wrapper.stash_descriptive
          datacite_xml = stash_descriptive.find { |elem| Resource.datacite?(elem) }
          resource = Resource.parse_xml(datacite_xml)

          doi = resource.doi
          {
            uuid: doi,
            dc_identifier_s: doi,
            dc_title_s: resource.default_title,
            dc_creator_sm: resource.creator_names.map { |i| i.to_s.strip }.delete_if(&:empty?),
            dc_type_s: resource.type,
            dc_description_s: resource.description_text_for(DescriptionType::ABSTRACT).to_s.strip,
            dc_subject_sm: resource.subjects.map { |i| i.value.to_s.strip }.delete_if(&:empty?),
            dct_spatial_sm: resource.geo_location_places,
            georss_box_s: resource.calc_bounding_box,
            solr_geom: resource.bounding_box_envelope,
            solr_year_i: resource.publication_year,
            dct_issued_dt: wrapper.embargo_end_date_xmlschema,
            dc_rights_s: wrapper.license.name,
            dc_publisher_s: resource.publisher.to_s.strip,
            dct_temporal_sm: resource.dct_temporal_dates
          }
        end

        def desc_from
          'Datacite 3.x'
        end

        def desc_to
          'Geoblacklight (Solr)'
        end
      end
    end
  end
end
