require 'datacite/mapping'
require 'stash/wrapper'
require 'time'

module Stash
  module Wrapper
    class StashWrapper
      def file_names
        inv = inventory
        inv.files.map(&:pathname) if inv
      end
    end
  end
end

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
        resource_type.value if resource_type
      end

      def funder_contrib
        @funder_contrib ||= contributors.find { |c| c.type == ContributorType::FUNDER }
      end

      def funder_name
        funder_contrib.name if funder_contrib
      end

      def funder_id
        funder_contrib.id if funder_contrib
      end

      def funder_id_value
        funder_id.value if funder_id
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
        geo_locations.select { |loc| loc.place.nil? }.map(&:point).compact
      end

      def self.datacite?(elem)
        elem.name == 'resource' && elem.namespace == 'http://datacite.org/schema/kernel-3'
      end
    end
  end
end
