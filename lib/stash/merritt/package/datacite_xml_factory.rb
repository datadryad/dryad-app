require 'stash_engine'
require 'stash_datacite'
require 'datacite/mapping'

module Datacite
  module Mapping
    class DataciteXMLFactory # rubocop:disable Metrics/ClassLength
      attr_reader :doi_value
      attr_reader :se_resource
      attr_reader :total_size_bytes
      attr_reader :version

      def initialize(doi_value:, se_resource:, total_size_bytes:, version:)
        @doi_value = doi_value
        @se_resource = se_resource
        @total_size_bytes = total_size_bytes
        @version = version && version.to_s
      end

      def build_datacite_xml(datacite_3: false)
        resource = build_resource(datacite_3: datacite_3)

        return resource.write_xml(mapping: :datacite_3) if datacite_3
        resource.write_xml
      end

      def build_resource(datacite_3: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        pub_year = se_resource.publication_years[0] # TODO: make this has_one instead of has_many

        resource = Resource.new(
          identifier: Identifier.from_doi(doi_value),
          creators: se_resource.creators.map do |c|
            Creator.new(
              name: c.creator_full_name,
              identifier: to_dcs_identifier(c.name_identifier),
              affiliations: c.affiliations.map(&:smart_name)
            )
          end,
          titles: se_resource.titles.map { |t| Title.new(value: t.title, type: t.title_type_mapping_obj) },
          publisher: to_dcs_publisher(se_resource.publisher),
          publication_year: to_dcs_pub_year(pub_year)
        )

        resource.language = 'en'
        resource.resource_type = to_dcs_type(se_resource.resource_type)
        resource.sizes = ["#{total_size_bytes} bytes"]
        resource.formats = se_resource.formats.map(&:format)
        resource.version = version

        add_subjects(resource)
        add_contributors(resource)
        add_dates(resource)
        add_alt_ids(resource)
        add_related_ids(resource)
        add_rights(resource)
        add_descriptions(resource)
        add_locations(resource)
        add_funding(resource, datacite_3: datacite_3)

        resource
      end

      private

      def to_dcs_type(sd_resource_type)
        ResourceType.new(resource_type_general: sd_resource_type.resource_type_general_mapping_obj,
                              value: sd_resource_type.resource_type)
      end

      def add_locations(resource)
        resource.geo_locations = se_resource.geolocations.map do |l|
          GeoLocation.new(
            place: l.datacite_mapping_place,
            point: l.datacite_mapping_point,
            box: l.datacite_mapping_box
          )
        end
      end

      def add_descriptions(resource)
        se_resource.descriptions.where.not(description: nil).each do |d|
          next if d.description.blank?
          resource.descriptions << Description.new(
            value: d.description,
            type: d.description_type_mapping_obj
          )
        end
      end

      def add_rights(resource)
        resource.rights_list = se_resource.rights.map do |r|
          Rights.new(
            value: r.rights,
            uri: to_uri(r.rights_uri)
          )
        end
      end

      def add_related_ids(resource)
        resource.related_identifiers = se_resource.related_identifiers.completed.map do |id|
          RelatedIdentifier.new(
            relation_type: id.relation_type_mapping_obj,
            value: id.related_identifier,
            identifier_type: id.related_identifier_type_mapping_obj,
            related_metadata_scheme: id.related_metadata_scheme,
            scheme_uri: to_uri(id.scheme_URI),
            scheme_type: id.scheme_type
          )
        end
      end

      def add_alt_ids(resource)
        resource.alternate_identifiers = se_resource.alternate_identifiers.map do |id|
          AlternateIdentifier.new(
            value: id.alternate_identifier,
            type: id.alternate_identifier_type
          )
        end
      end

      def add_dates(resource)
        resource.dates = se_resource.datacite_dates.where.not(date: nil).map do |d|
          sd_date = d.date
          Date.new(
            type: d.date_type_mapping_obj,
            value: sd_date
          )
        end
      end

      def add_subjects(resource)
        resource.subjects = se_resource.subjects.map { |s| Subject.new(value: s.subject) }
      end

      def add_contributors(resource)
        se_resource.contributors.completed.where.not(contributor_type: 'funder').each do |c|
          resource.contributors << Contributor.new(
            name: c.contributor_name,
            identifier: to_dcs_identifier(c.name_identifier),
            type: c.contributor_type_mapping_obj,
            affiliations: c.affiliations.map(&:long_name)
          )
        end
      end

      def add_funding(resource, datacite_3: false)
        sd_funder_contribs = se_resource.contributors.completed.where(contributor_type: 'funder')
        if datacite_3
           sd_funder_contribs.each do |c|
            contrib_name = c.contributor_name
            award_num = c.award_number
            desc_text = "Data were created with funding from #{contrib_name}"
            desc_text << " under grant(s) #{award_num}." if award_num
            desc = Description.new(type: DescriptionType::OTHER, value: desc_text)
            resource.descriptions << desc

            contrib = Contributor.new(
              name: contrib_name,
              identifier: to_dcs_identifier(c.name_identifier),
              type: ContributorType::FUNDER
            )
            resource.contributors << contrib
          end
        else
          resource.funding_references = sd_funder_contribs.map do |c|
            FundingReference.new(
              name: c.contributor_name,
              award_number: c.award_number
            )
          end
        end
      end

      def to_dcs_identifier(sd_name_ident)
        return unless sd_name_ident
        sd_scheme_uri = sd_name_ident.scheme_URI
        NameIdentifier.new(
          scheme: sd_name_ident.name_identifier_scheme,
          scheme_uri: sd_scheme_uri && to_uri(sd_scheme_uri),
          value: sd_name_ident.name_identifier
        )
      end

      def to_dcs_publisher(sd_publisher)
        return 'unknown' unless sd_publisher
        sd_publisher.publisher
      end

      def to_dcs_pub_year(sd_pub_year)
        return ::Date.today.year unless sd_pub_year
        sd_pub_year.publication_year
      end

      def to_uri(uri_or_str)
        ::XML::MappingExtensions.to_uri(uri_or_str)
      end
    end
  end
end
