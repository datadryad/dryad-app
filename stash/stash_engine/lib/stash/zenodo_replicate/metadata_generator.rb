module Stash
  module ZenodoReplicate

    # to generate the metadata for the Zenodo API, see https://developers.zenodo.org/#depositions
    # and the "Deposit metadata" they request, which is kind of similar to ours, but slightly different
    class MetadataGenerator
      def initialize(resource:)
        @resource = resource
      end

      # returns a hash of the metadata from the list of methods, you can make it into json to send
      def metadata
        out_hash = {}.with_indifferent_access
        # took out the DOI since I don't want to use it in zenodo because of versioning problems
        %i[doi upload_type publication_date title creators description access_right license
           keywords notes related_identifiers method].each do |meth|
          result = send(meth)
          out_hash[meth] = result unless result.blank?
        end
        out_hash
      end

      def doi
        "https://doi.org/#{bork_doi_for_zenodo_sandbox(doi: @resource.identifier.identifier)}"
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
        @resource.authors.map { |a| creator(author: a) }
      end

      def creator(author:)
        affil = author.affiliations.first&.long_name
        orc = author.author_orcid

        hsh = { name: author.author_full_name }
        hsh[:affiliation] = affil unless affil.blank?
        hsh[:orcid] = orc unless orc.blank?
        hsh
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
          { relation: ri.relation_type_friendly&.camelize(:lower), identifier: ri.related_identifier }
        end

        related ||= []

        related.push(
          relation: 'isIdenticalTo', identifier: "https://doi.org/#{@resource.identifier.identifier}"
        )
      end

      def method
        @resource.descriptions.where(description_type: 'methods')&.map(&:description)&.join("\n")
      end

      private

      # this is a workaround for the zenodo sandbox in non-production environments since they claim all test DOIs
      # as their own and their added functionality for re-editing things doesn't work with them unless we give them
      # a non-test DOI so they don't do the wrong thing.
      def bork_doi_for_zenodo_sandbox(doi:)
        return doi if Rails.env == 'production'

        doi.gsub(/^10\.5072/, '10.55072') # bork our datacite test dois into non-test shoulders because Zenodo reserves them as their own
      end

    end
  end
end
