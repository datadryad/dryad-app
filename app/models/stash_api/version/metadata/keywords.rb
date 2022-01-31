# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Keywords < MetadataItem

        def value
          @resource.subjects.non_fos.map(&:subject)
        end
      end
    end
  end
end
