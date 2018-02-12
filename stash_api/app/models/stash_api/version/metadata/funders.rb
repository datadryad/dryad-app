# frozen_string_literal: true

module StashApi
  class Version
    class Metadata
      class Funders < MetadataItem

        def value
          @resource.contributors.where(contributor_type: 'funder').map do |funder|
            {
              organization: funder.contributor_name,
              awardNumber: funder.award_number
            }
          end
        end
      end
    end
  end
end
