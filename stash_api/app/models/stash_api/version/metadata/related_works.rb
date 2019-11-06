# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class RelatedWorks < MetadataItem

        def value
          @resource.related_identifiers.map do |r|
            {
              relationship: r.relation_type_friendly,
              identifierType: r.related_identifier_type_friendly,
              identifier: r.related_identifier
            }
          end
        end
      end
    end
  end
end
