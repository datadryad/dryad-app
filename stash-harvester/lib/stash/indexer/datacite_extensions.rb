require 'datacite/mapping'
require 'stash/wrapper'
require 'time'

module Stash
  module Wrapper
    class StashWrapper
      def embargo_end_date_xmlschema
        d = embargo_end_date
        Time.utc(d.year, d.month, d.day).xmlschema
      end
    end
  end
end

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

    class Resource

      def default_title
        title = titles.find { |t| t.type.nil? }
        title.value.to_s.strip if title
      end

      def doi
        identifier.to_doi
      end

      def type
        general_type.value.to_s.strip if general_type
      end

      def general_type
        resource_type.resource_type_general if resource_type
      end

      def grant_number
        grant_regex = /^\s*Data were created with .* under grant (.*)\.\s*$/
        funding = descriptions.find(&:funding?)
        return nil unless funding

        match_data = grant_regex.match(funding.value)
        match_data[1] if match_data
      end

      def usage_notes
        usage = descriptions.find(&:usage?)
        usage.value if usage
      end

      def description_text_for(type)
        desc = descriptions.find { |d| d.type = type }
        desc.value if desc
      end

      def geo_location_places
        geo_locations.map(&:place).compact
      end

      def geo_location_boxes
        geo_locations.map(&:box).compact
      end

      def geo_location_points
        geo_locations.map(&:point).compact
      end

      def self.datacite?(elem)
        elem.name == 'resource' && Datacite::Mapping.datacite_namespace?(elem)
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
        GeoLocationBox.new(lat_min, long_min, lat_max, long_max) if lat_min && long_min && lat_max && long_max
      end

      # converts to DublinCore Terms, temporal, see http://journal.code4lib.org/articles/9710 or
      # https://github.com/geoblacklight/geoblacklight-schema and seems very similar to the annotation going
      # into the original DataCite element.  https://terms.tdwg.org/wiki/dcterms:temporal
      #
      # method takes the values supplied and also adds every year for a range so people can search for
      # any of those years which may not be explicitly named
      def dct_temporal_dates # rubocop:disable Metrics/AbcSize
        items = dates.map(&:to_s).compact
        year_range_items = dates.map do |i|
          (i.range_start.year..i.range_end.year).to_a.map(&:to_s) if i.range_start && i.range_end && i.range_start.year && i.range_end.year
        end
        (items + year_range_items).compact.flatten.uniq
      end

      def bounding_box_envelope
        (bbox = calc_bounding_box) ? bbox.to_envelope : nil
      end
    end
  end
end
