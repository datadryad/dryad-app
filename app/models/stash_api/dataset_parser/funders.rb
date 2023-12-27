module StashApi
  class DatasetParser
    class Funders < StashApi::DatasetParser::BaseParser

      # funders hash looks like this
      # "funders": [
      #   {
      #     "organization": "Savannah River Operations Office, U.S. Department of Energy",
      #     "awardNumber": "12345"
      #     "identifierType": "crossref_funder_id",
      #     "identifier": "http://dx.doi.org/387867/3798789"
      #   }
      # ]

      def parse
        clear
        return if @hash['funders'].nil?

        @hash['funders'].each do |funder|
          @resource.contributors << StashDatacite::Contributor.create(
            contributor_name: funder['organization'],
            contributor_type: 'funder',
            identifier_type: funder['identifierType'] || 'crossref_funder_id',
            name_identifier_id: funder['identifier'],
            award_number: funder['awardNumber'],
            award_description: funder['awardDescription']
          )
        end
      end

      private

      def clear
        @resource.contributors.where(contributor_type: 'funder').destroy_all
      end

    end
  end
end
