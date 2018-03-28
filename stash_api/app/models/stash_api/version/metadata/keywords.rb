# frozen_string_literal: true
require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Keywords < MetadataItem

        def value
          @resource.subjects.map(&:subject)
        end
      end
    end
  end
end
