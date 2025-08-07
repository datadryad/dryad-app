# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class HsiStatement < MetadataItem

        def value
          items = @resource.descriptions.where(description_type: 'hsi_statement').map(&:description)
          return items.first unless items.blank?

          nil
        end
      end
    end
  end
end
