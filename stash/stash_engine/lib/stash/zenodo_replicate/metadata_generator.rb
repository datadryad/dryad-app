module Stash
  module ZenodoReplicate

    # to generate the metadata for the Zenodo API, see https://developers.zenodo.org/#depositions
    # and the "Deposit metadata" they request, which is kind of similar to ours, but slightly different
    class MetadataGenerator
      def initialize(resource:)
        @resource = resource
      end


      def upload_type
        @resource.resource_type.resource_type_general
        # @resource&.&resource_type&.resource_type_general
      end

      def publication_date
        @resource&.publication_date&.iso8601
      end

      def title
        @resource.title
      end

      def creators
        @resource.authors.map{|a| creator(author: a)}
      end

      def creator(author:)
        {
            name: author.author_full_name,
            affiliation: author.affiliations.first&.long_name,
            orcid: author.author_orcid
        }
      end

      def description
        @resource.descriptions.where(description_type: 'abstract').first.description
      end

      def access_right
        'open'
      end

      def license
        if @resource.rights.first&.rights_uri&.include?('/zero')
          'cc-zero'
        else
          'cc-by'
        end
      end

      def keywords
        @resource.subjects&.map(&:subject)
      end

      def notes
        @resource.descriptions.where(description_type: 'other')&.map(&:description)&.join("\n")
      end

      def related_identifiers
        related = @resource.related_identifiers.map do |ri|
          {relation: ri.relation_type_friendly&.camelize(:lower), identifier: ri.related_identifier }
        end

        related ||= []

        related.push(
            { relation: 'isIdenticalTo', identifier: "https://doi.org/#{@resource.identifier.identifier})" }
        )

      end

      def method
        @resource.descriptions.where(description_type: 'methods')&.map(&:description)&.join("\n")
      end


    end
  end
end