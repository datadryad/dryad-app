# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class TemporalCoverages < MetadataItem

        def value
          items = StashDatacite::TemporalCoverage.where(resource_id: @resource.id)
          return items.to_a.map(&:description) unless items.blank?
          nil
        end
      end
    end
  end
end
