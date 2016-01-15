require 'datacite/mapping'
require 'time'

module Datacite
  module Mapping

    class Description
      def funding?
        # TODO: Make 'data were created with' etc. a constant or something and move it to Datacite::Mapping
        type == DescriptionType::OTHER && value.start_with?('Data were created with funding')
      end

      def usage?
        type == DescriptionType::OTHER && !funding?
      end
    end

    class Resource

      def default_title
        title = titles.find { |t| t.type.nil? }
        title.value if title
      end

      def creator_names
        creators.map(&:name)
      end

      def creator_affiliations
        creators.map(&:affiliations)
      end

      def type
        resource_type.resource_type_general.value if resource_type
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

      def embargo_type
        embargo.type.value if embargo
      end

      def embargo_end_date
        return nil unless embargo
        d = embargo.end_date
        Time.utc(d.year, d.month, d.day).xmlschema
      end

      def self.datacite?(elem)
        elem.name == 'resource' && elem.namespace == 'http://datacite.org/schema/kernel-3'
      end
    end
  end
end
