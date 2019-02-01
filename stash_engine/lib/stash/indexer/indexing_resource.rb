module Stash
  module Indexer
    class IndexingResource
      # takes a database resource object
      def initialize(resource:)
        @resource = resource
      end

      def default_title
        @resource&.title
      end

      def doi
        @resource&.identifier&.to_s
      end

      def type
        # TODO: find out what this is and fix
        # general_type.value.to_s.strip if general_type
      end

      def general_type
        # TODO: find out what this is and fix
        # resource_type.resource_type_general if resource_type
      end

      def grant_number
        funders = @resource.contributors.where(contributor_type: 'funder')
        return nil unless funders.count.positive?
        funders.first.award_number
      end

      def usage_notes
        usage = @resource.descriptions.type_abstract
        return nil unless usage.count.positive?
        Loofah.fragment(usage.first.description).text
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