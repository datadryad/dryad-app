require 'datacite/mapping'


# these patch datacite mapping modules for some extra stuff David added
module Datacite
  module Mapping

    DATACITE_NAMESPACES = [DATACITE_3_NAMESPACE, DATACITE_4_NAMESPACE].freeze
    DATACITE_NAMESPACE_URIS = DATACITE_NAMESPACES.map(&:uri).freeze

    def self.datacite_namespace?(elem)
      (ns = elem.namespace) && DATACITE_NAMESPACE_URIS.include?(ns)
    end

    class Description
      def funding?
        # TODO: Make 'data were created with' etc. a constant or something and move it to Datacite::Mapping
        type == DescriptionType::OTHER && value.start_with?('Data were created with funding')
      end

      def usage?
        type == DescriptionType::OTHER && !funding?
      end
    end

    class GeoLocationBox
      # Expresses the coordinates of this `GeoLocationBox` in [OpenGIS Well-Known Text](http://www.opengeospatial.org/standards/sfa)
      # `ENVELOPE` format: `ENVELOPE(minX, maxX, maxY, minY)`. As the [Solr docs](https://cwiki.apache.org/confluence/display/solr/Spatial+Search)
      # say: "The parameter ordering is unintuitive but that's what the spec calls for."
      # @return [String] the coordinates of this box as a WKT `ENVELOPE`
      def to_envelope
        "ENVELOPE(#{west_longitude}, #{east_longitude}, #{north_latitude}, #{south_latitude})"
      end
    end

    class Identifier
      def to_doi
        "doi:#{value}"
      end
    end
  end
end

module Stash
  module Indexer
    class IndexingResource

      DESCRIPTION_TYPES_TO_DB = { Datacite::Mapping::DescriptionType::ABSTRACT => 'abstract',
                                  Datacite::Mapping::DescriptionType::METHODS => 'methods',
                                  Datacite::Mapping::DescriptionType::OTHER => 'other' }.freeze

      # takes a database resource object.
      def initialize(resource:)
        @resource = resource
      end

      # this is really what we want to get out of this for solr indexing, the rest is for compatibility with old indexing
      def to_index_document # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        {
            uuid: doi,
            dc_identifier_s: doi,
            dc_title_s: default_title,
            dc_creator_sm: creator_names.map { |i| i.strip },
            dc_type_s: type,
            dc_description_s: description_text_for(Datacite::Mapping::DescriptionType::ABSTRACT).to_s.strip,
            dc_subject_sm: subjects,
            dct_spatial_sm: geo_location_places,
            georss_box_s: calc_bounding_box,
            solr_geom: bounding_box_envelope,
            solr_year_i: publication_year,
            dct_issued_dt: issued_date,
            dc_rights_s: license_name,
            dc_publisher_s: publisher,
            dct_temporal_sm: dct_temporal_dates
        }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def default_title
        @resource&.title&.strip
      end

      def doi
        @resource&.identifier&.to_s
      end

      def type
        # This is something like 'Software'
        @resource&.resource_type&.resource_type_general_friendly
      end

      def general_type
        # This is class like Datacite::Mapping::ResourceTypeGeneral
        @resource&.resource_type&.resource_type_general_mapping_obj
      end

      def creator_names
        authors = @resource.authors
        return [] if authors.empty?
        authors.map(&:author_full_name).reject(&:blank?)
      end

      def subjects
        @resource.subjects.map{|s| s.subject&.strip}.reject(&:blank?)
      end

      def publication_year
        @resource.publication_years&.first&.publication_year&.to_i
      end

      def issued_date
        @resource&.publication_date&.iso8601
      end

      def license_name
        # we could make this call nicer by adding an association (or simulating one) on identifier
        StashEngine::License.by_id(@resource.identifier.license_id)[:name]
      end

      def publisher
        @resource&.publisher&.publisher
      end

      def grant_number
        @resource.contributors.where(contributor_type: 'funder').map(&:award_number).reject(&:blank?).map(&:strip).join("\r")
      end

      def usage_notes
        description_text_for(Datacite::Mapping::DescriptionType::OTHER)
      end

      # called like resource.description_text_for(DescriptionType::ABSTRACT).to_s.strip
      # I believe this returns the test for things besides usage notes
      def description_text_for(type)
        the_type = DESCRIPTION_TYPES_TO_DB[type]
        return nil unless the_type
        @resource.descriptions.where(description_type: the_type).map(&:description).reject(&:blank?).map{|i| Loofah.fragment(i).text.strip }.join("\r")
      end

      # gives array of names
      def geo_location_places
        @resource.geolocations.map(&:geolocation_place).compact.map(&:geo_location_place).reject(&:blank?)
      end

      # using the icky datacite mapping objects
      def geo_location_boxes
        @resource.geolocations.map(&:geolocation_box).compact.map{|i| db_box_to_dc_mapping(db_box: i)}.compact
      end

      def geo_location_points
        @resource.geolocations.map(&:geolocation_point).compact.map{|i| db_point_to_dc_mapping(db_point: i)}.compact
      end

      def self.datacite?(elem)
        true
        # elem.name == 'resource' && Datacite::Mapping.datacite_namespace?(elem)
      end

      def calc_bounding_box # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        lat_min, lat_max, long_min, long_max = nil
        geo_location_points.each do |pt|
          lat_min = [lat_min, pt.latitude].compact.min
          lat_max = [lat_max, pt.latitude].compact.max
          long_min = [long_min, pt.longitude].compact.min
          long_max = [long_max, pt.longitude].compact.max
        end
        geo_location_boxes.each do |box|
          lat_min = [lat_min, box.south_latitude, box.north_latitude].compact.min
          lat_max = [lat_max, box.south_latitude, box.north_latitude].compact.max
          long_min = [long_min, box.west_longitude, box.east_longitude].compact.min
          long_max = [long_max, box.west_longitude, box.east_longitude].compact.max
        end
        Datacite::Mapping::GeoLocationBox.new(lat_min, long_min, lat_max, long_max) if lat_min && long_min && lat_max && long_max
      end

      # converts to DublinCore Terms, temporal, see http://journal.code4lib.org/articles/9710 or
      # https://github.com/geoblacklight/geoblacklight-schema and seems very similar to the annotation going
      # into the original DataCite element.  https://terms.tdwg.org/wiki/dcterms:temporal
      #
      # method takes the values supplied and also adds every year for a range so people can search for
      # any of those years which may not be explicitly named
      def dct_temporal_dates # rubocop:disable Metrics/AbcSize
        items = @resource.datacite_dates.map(&:date).reject(&:blank?)
        items.map!{ |dt| Date.iso8601(dt).strftime('%Y-%m-%d') }
        return items

        # the below is the old stuff.  We don't have ranges in our dates.
        # items = dates.map(&:to_s).compact
        # year_range_items = dates.map do |i|
        #   (i.range_start.year..i.range_end.year).to_a.map(&:to_s) if i.range_start && i.range_end && i.range_start.year && i.range_end.year
        # end
        # (items + year_range_items).compact.flatten.uniq
      end

      def bounding_box_envelope
        (bbox = calc_bounding_box) ? bbox.to_envelope : nil
      end

      private

      # helpers to convert to datacite mapping
      def db_box_to_dc_mapping(db_box:)
        return nil unless db_box.sw_latitude && db_box.ne_latitude && db_box.sw_longitude && db_box.ne_longitude
        Datacite::Mapping::GeoLocationBox.new(south_latitude: db_box.sw_latitude.to_f,
                                              west_longitude: db_box.sw_longitude.to_f,
                                              north_latitude: db_box.ne_latitude.to_f,
                                              east_longitude: db_box.ne_longitude.to_f)
      end

      def db_point_to_dc_mapping(db_point:)
        return nil unless db_point.latitude && db_point.longitude
        Datacite::Mapping::GeoLocationPoint.new(latitude: db_point.latitude.to_f, longitude: db_point.longitude.to_f)
      end
    end
  end
end