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
              email: parse_email(a.author_email),
              affiliation: a.try(:affiliation).try(:smart_name),
              affiliationROR: a.try(:affiliation).try(:ror_id),
              orcid: a.author_orcid,
              order: a.author_order
            }
          end
        end
      end
    end
  end
end
