# frozen_string_literal: true

require_relative 'metadata_item'

module StashApi
  class Version
    class Metadata
      class Funders < MetadataItem

        def value
          @resource.contributors.where(contributor_type: 'funder').where.not(name_identifier_id: '0').map do |funder|
            {
              organization: funder.contributor_name,
              identifierType: funder.identifier_type,
              identifier: funder.name_identifier_id,
              awardNumber: funder.award_number,
              awardURI: funder.award_uri,
              awardDescription: funder.award_description,
              awardTitle: funder.award_title,
              order: funder.funder_order
            }
          end
        end
      end
    end
  end
end
