require 'stash/indexer/datacite_extensions' # This is where Datacite::Mapping comes from and stash::wrapper::stashwrapper
require 'stash/indexer/metadata_mapper'  # inherits from this one

module Stash
  module Indexer
    module DatabaseGeoblacklight

      class Mapper < MetadataMapper
        # include Datacite::Mapping
        # metadata_mapping 'database_geoblacklight'

        def initialize(*opts)
          super
        end

        def to_index_document(resource:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

          # I believe this is originally the Datacite::Mapping::Resource in the crazy datacite_extensions file.
          # Nice job hiding and obscuring it.
          i_resource = IndexingResource.new(resouce: resource)

          doi = i_resource.doi
          {
            uuid: doi,
            dc_identifier_s: doi,
            dc_title_s: i_resource.default_title,
            dc_creator_sm: i_resource.creator_names.map { |i| i.to_s.strip }.delete_if(&:empty?),
            dc_type_s: i_resource.type,
            dc_description_s: i_resource.description_text_for(DescriptionType::ABSTRACT).to_s.strip,
            dc_subject_sm: i_resource.subjects.map { |i| i.value.to_s.strip }.delete_if(&:empty?),
            dct_spatial_sm: i_resource.geo_location_places,
            georss_box_s: i_resource.calc_bounding_box,
            solr_geom: i_resource.bounding_box_envelope,
            solr_year_i: i_resource.publication_year,
            dct_issued_dt: nil, # was wrapper.embargo_end_date_xmlschema
            dc_rights_s: nil, # was wrapper.license.name
            dc_publisher_s: i_resource.publisher.to_s.strip,
            dct_temporal_sm: i_resource.dct_temporal_dates
          }
        end

        def desc_from
          'Internal database metadata (DataCite 3.1-ish)'
        end

        def desc_to
          'Geoblacklight (Solr)'
        end
      end
    end
  end
end
