# frozen_string_literal: true
require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Authors < MetadataItem

        def value
          @resource.authors.map do |a|
            {
              firstName: a.author_first_name,
              lastName: a.author_last_name,
              email: a.author_email,
              affiliation: a.try(:affiliation).try(:smart_name),
              orcid: a.author_orcid
            }
          end
        end
      end
    end
  end
end
