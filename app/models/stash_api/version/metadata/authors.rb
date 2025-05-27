# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Authors < MetadataItem

        def value
          @resource.authors.map(&:as_json)
        end
      end
    end
  end
end
