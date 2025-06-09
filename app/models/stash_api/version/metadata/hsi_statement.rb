# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class HsiStatement < MetadataItem

        def value
          items = @resource.descriptions.where(description_type: 'usage_notes').map(&:description)
          return items.first unless items.blank?

          nil
        end
      end
    end
  end
end
