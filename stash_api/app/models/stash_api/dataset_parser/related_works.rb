require_relative 'base_parser'

module StashApi
  class DatasetParser
    class RelatedWorks < StashApi::DatasetParser::BaseParser

      # Related Works look like this and use a constrainted list of relationships and identifier types
      # "relatedWorks": [
      #   {
      #     "relationship": "Cites",
      #     "identifierType": "URL",
      #     "identifier": "http://example.org/cats"
      #   } ]

      # lists of allowed values
      #   StashDatacite::RelatedIdentifier::RelationTypes
      #   StashDatacite::RelatedIdentifier::RelatedIdentifierTypes
      LowerRelationTypes = StashDatacite::RelatedIdentifier::RelationTypes.map(&:downcase)
      LowerIdentifierTypes = StashDatacite::RelatedIdentifier::RelatedIdentifierTypes.map(&:downcase)

      def parse # rubocop:disable Metrics/AbcSize
        clear
        return if @hash['relatedWorks'].blank?
        @hash['relatedWorks'].each do |rw|
          next if rw.blank? || !LowerRelationTypes.include?(rw['relationship']&.downcase) ||
              !LowerIdentifierTypes.include?(rw['identifierType']&.downcase)
          @resource.related_identifiers << StashDatacite::RelatedIdentifier.create(
            related_identifier: rw['identifier'],
            related_identifier_type: rw['identifierType']&.downcase,
            relation_type: rw['relationship']&.downcase
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
