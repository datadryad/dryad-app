# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Funders < MetadataItem

        def value
          @resource.contributors.where(contributor_type: 'funder').map do |funder|
            {
              organization: funder.contributor_name,
              identifierType: funder.identifier_type,
              identifier: funder.name_identifier_id,
              awardNumber: funder.award_number,
              awardDescription: funder.award_description,
              order: funder.funder_order
            }
          end
        end
      end
    end
  end
end
