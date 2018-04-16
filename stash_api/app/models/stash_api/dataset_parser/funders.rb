module StashApi
  class DatasetParser
    class Funders

      def initialize(resource:, hash:)
        @resource = resource
        @hash = hash
      end

      # funders hash looks like this
      # "funders": [
      #   {
      #     "organization": "Savannah River Operations Office, U.S. Department of Energy",
      #     "awardNumber": "12345"
      #   }
      # ]

      def parse
        clear
        return if @hash['funders'].nil?
        @hash['funders'].each do |funder|
          @resource.contributors << StashDatacite::Contributor.create(contributor_name: funder['organization'],
                                                                      contributor_type: 'funder', award_number: funder['awardNumber'])
        end
      end

      private

      def clear
        @resource.contributors.where(contributor_type: 'funder').destroy_all
      end

    end
  end
end
