require_relative 'base_parser'

module StashApi
  class DatasetParser
    class RelatedWorks < StashApi::DatasetParser::BaseParser

      # Related Works look like this and use a constrainted list of relationships and identifier types
      # "relatedWorks": [
      #   {
      #     "relationship": "software",
      #     "identifierType": "URL",
      #     "identifier": "http://example.org/cats"
      #   } ]

      # lists of allowed values
      LowerWorkTypes = StashDatacite::RelatedIdentifier.work_types.map(&:first)
      LowerIdentifierTypes = StashDatacite::RelatedIdentifier::RelatedIdentifierTypes.map(&:downcase)

      def parse
        clear
        return if @hash['relatedWorks'].blank?

        @hash['relatedWorks'].each do |rw|
          next if rw.blank? || !LowerWorkTypes.include?(rw['relationship']&.downcase) ||
              !LowerIdentifierTypes.include?(rw['identifierType']&.downcase)

          @resource.related_identifiers << StashDatacite::RelatedIdentifier.create(
            related_identifier: rw['identifier'],
            related_identifier_type: rw['identifierType']&.downcase,
            work_type: rw['relationship']&.downcase,
            relation_type: StashDatacite::RelatedIdentifier::WORK_TYPES_TO_RELATION_TYPE[rw['relationship']&.downcase]
          )
        end
      end

      private

      def clear
        @resource.related_identifiers.destroy_all
      end

    end
  end
end
