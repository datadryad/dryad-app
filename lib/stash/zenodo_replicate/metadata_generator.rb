require 'cgi'

module Stash
  module ZenodoReplicate

    # to generate the metadata for the Zenodo API, see https://developers.zenodo.org/#depositions
    # and the "Deposit metadata" they request, which is kind of similar to ours, but slightly different
    class MetadataGenerator
      # currently dataset_type may be :data, :software or :supp (for supplemental)
      def initialize(resource:, dataset_type: :data)
        # Software uploads are a little different because 1) they use Zenodo DOIs, and 2) They use a different license
        # than the dataset license and they should be 'software' rather than 'dataset'.
        @resource = resource
        @dataset_type = dataset_type
      end

      # returns a hash of the metadata from the list of methods, you can make it into json to send
      def metadata
        out_hash = {}.with_indifferent_access
        %i[doi upload_type publication_date title creators description access_right license
           keywords notes related_identifiers method locations communities].each do |meth|
          next if meth == 'doi' && @dataset_type != :data

          result = send(meth)
          out_hash[meth] = result unless result.blank?
        end
        out_hash
      end

      def doi
        "https://doi.org/#{bork_doi_for_zenodo_sandbox(doi: @resource.identifier.identifier)}"
      end

      def upload_type
        return @resource.resource_type.resource_type_general if @dataset_type == :data
        return 'software' if @dataset_type == :software

        'other'
      end

      def publication_date
        # @resource&.publication_date&.iso8601
        @resource&.publication_date&.strftime('%Y-%m-%d')
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
        @resource.descriptions.where(description_type: 'abstract')&.first&.description || 'No abstract available'
      end

      def access_right
        'open'
      end

      def license
        return license_for_data if @dataset_type == :data

        return 'CC-BY-4.0' if @dataset_type == :supp

        license_for_software
      end

      def license_for_data
        if @resource.rights.first&.rights_uri&.include?('/zero')
          'cc-zero'
        else
          'cc-by'
        end
      end

      def license_for_software
        @resource&.identifier&.software_license&.identifier || 'MIT'
      end

      def keywords
        @resource.subjects.non_fos&.map(&:subject)
      end

      def notes
        my_notes = @resource.descriptions.where(description_type: 'other')&.map(&:description)&.join("\n")
        funder_info = @resource.contributors.where(contributor_type: 'funder')
          .where('dcs_contributors.contributor_name IS NOT NULL')
          .map { |contrib| funding_text(contrib) }.join('</p><p>')
        funder_info = "<p>#{funder_info}</p>" unless funder_info.blank?
        "#{my_notes}#{funder_info}".strip
      end

      def related_identifiers
        case @dataset_type
        when :software
          related_software
        when :supp
          related_supp
        else
          related_data
        end
      end

      # this only gets called for data deposits and is basically the same metadata as our dataset
      def related_data
        @resource.related_identifiers.where(verified: true).where(hidden: false).map do |ri|
          { relation: ri.relation_type_friendly&.camelize(:lower), identifier: ri.related_identifier }
        end || []
      end

      # this only gets called for zenodo software deposits, we have to add link back to our dataset from their software
      def related_software
        related = @resource.related_identifiers.where(verified: true).where(hidden: false).where.not(added_by: 'zenodo').map do |ri|
          { relation: ri.relation_type_friendly&.camelize(:lower), identifier: ri.related_identifier }
        end

        # their software is source of our data
        related.push(relation: 'isSourceOf',
                     identifier: StashDatacite::RelatedIdentifier.standardize_doi(@resource.identifier.identifier),
                     scheme: 'doi')
        related || []
      end

      # this only gets called for zenodo supplemental deposits,  we have to add link back to our dataset from their supplemental
      def related_supp
        related = @resource.related_identifiers.where(verified: true).where(hidden: false).where.not(added_by: 'zenodo').map do |ri|
          { relation: ri.relation_type_friendly&.camelize(:lower), identifier: ri.related_identifier }
        end

        # their supplemental information isDerivedFrom our dataset
        related.push(relation: 'isDerivedFrom',
                     identifier: StashDatacite::RelatedIdentifier.standardize_doi(@resource.identifier.identifier),
                     scheme: 'doi')
        related || []
      end

      def method
        @resource.descriptions.where(description_type: 'methods')&.map(&:description)&.join("\n")
      end

      def locations
        @resource.geolocations.map do |geo|
          location(geo)
        end.compact
      end

      def communities
        [{ identifier: APP_CONFIG.zenodo.community_id }]
      end

      def location(geolocation)
        # no way to represent boxes in zenodo?
        return nil if geolocation.place_id.nil? && geolocation.point_id.nil?

        hsh = {}
        unless geolocation.point_id.nil?
          hsh['lat'] = geolocation.geolocation_point.latitude
          hsh['lon'] = geolocation.geolocation_point.longitude
        end
        hsh['place'] = geolocation.geolocation_place.geo_location_place unless geolocation.place_id.nil?
        hsh
      end

      private

      # this is a workaround for the zenodo sandbox in non-production environments since they claim all test DOIs
      # as their own and their added functionality for re-editing things doesn't work with them unless we give them
      # a non-test DOI so they don't do the wrong thing.
      def bork_doi_for_zenodo_sandbox(doi:)
        return doi if Rails.env == 'production'

        # bork our datacite test dois into non-test shoulders because Zenodo reserves them as their own, don't bork their own DOIs
        doi.gsub!(/^10\.5072/, '10.55072') if @dataset_type == :data
        doi
      end

      def funding_text(contributor)
        ["Funding provided by: #{CGI.escapeHTML(contributor.contributor_name.to_s)}",
         (contributor.name_identifier_id.nil? ? nil : "Crossref Funder Registry ID: #{CGI.escapeHTML(contributor.name_identifier_id)}"),
         (contributor.award_number.nil? ? nil : "Award Number: #{CGI.escapeHTML(contributor.award_number)}")].compact.join('<br/>')
      end

    end

  end
end
