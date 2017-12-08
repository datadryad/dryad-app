module StashApi
  class Version
    class Metadata
      class Methods < MetadataItem

        def value
          items = @resource.descriptions.type_methods.map do |desc|
            desc.description
          end
          return items.first unless items.blank?
          nil
        end
      end
    end
  end
end