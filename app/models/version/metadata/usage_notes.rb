# frozen_string_literal: true

require_relative 'metadata_item'

  class Version
    class Metadata
      class UsageNotes < MetadataItem

        def value
          items = @resource.descriptions.type_other.map(&:description)
          return items.first unless items.blank?

          nil
        end
      end
    end
  end
