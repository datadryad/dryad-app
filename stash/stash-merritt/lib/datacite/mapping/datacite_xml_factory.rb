require 'datacite/mapping'
require 'action_controller'

module Datacite
  module Mapping
    class DataciteXMLFactory # rubocop:disable Metrics/ClassLength
      DEFAULT_RESOURCE_TYPE = ResourceType.new(resource_type_general: ResourceTypeGeneral::DATASET, value: 'dataset')

      attr_reader :doi_value, :se_resource_id, :total_size_bytes, :version

      def initialize(doi_value:, se_resource_id:, total_size_bytes:, version:)
        @doi_value = doi_value
        @se_resource_id = se_resource_id
        @total_size_bytes = total_size_bytes
        @version = version && version.to_s
      end

      def build_datacite_xml(datacite_3: false)
        dcs_resource = build_resource(datacite_3: datacite_3)

        return dcs_resource.write_xml(mapping: :datacite_3) if datacite_3

        dcs_resource.write_xml
      end

      def build_resource(datacite_3: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        pub_year = se_resource.publication_years[0] # TODO: make this has_one instead of has_many

        dcs_resource = Resource.new(
          identifier: Identifier.from_doi(doi_value),
          creators: se_resource.authors.map do |c|
            Creator.new(
              name: c.author_full_name,
              identifier: dcs_identifier_from(c.author_orcid),
              affiliations: c.affiliations.map do |a|
                if a.ror_id && !datacite_3
                  Affiliation.new(
                    identifier: a.ror_id,
                    identifier_scheme: 'ROR',
                    scheme_uri: 'https://ror.org',
                    value: a.smart_name
                  )
                else
                  Affiliation.new(value: a.smart_name)
                end
              end
            )
          end,
          titles: [Title.new(value: se_resource.title, type: nil)],
          publisher: to_dcs_publisher(se_resource.publisher),
          publication_year: to_dcs_pub_year(pub_year)
        )

        dcs_resource.language = 'en'
        dcs_resource.resource_type = to_dcs_type(se_resource.resource_type)
        dcs_resource.sizes = ["#{total_size_bytes} bytes"]
        dcs_resource.formats = se_resource.formats.map(&:format)
        dcs_resource.version = version

        add_subjects(dcs_resource)
        add_contributors(dcs_resource, datacite_3: datacite_3)
        add_dates(dcs_resource)
        add_alt_ids(dcs_resource)
        add_related_ids(dcs_resource)
        add_rights(dcs_resource)
        add_descriptions(dcs_resource)
        add_locations(dcs_resource)
        add_funding(dcs_resource, datacite_3: datacite_3)

        dcs_resource
      end

      private

      def se_resource
        @se_resource ||= StashEngine::Resource.find(se_resource_id)
      end

      def to_dcs_type(sd_resource_type)
        return DEFAULT_RESOURCE_TYPE unless sd_resource_type

        ResourceType.new(resource_type_general: sd_resource_type.resource_type_general_mapping_obj,
                         value: sd_resource_type.resource_type)
      end

      def add_locations(dcs_resource)
        dcs_resource.geo_locations = se_resource.geolocations.map do |l|
          GeoLocation.new(
            place: l.datacite_mapping_place,
            point: l.datacite_mapping_point,
            box: l.datacite_mapping_box
          )
        end
      end

      def add_descriptions(dcs_resource)
        se_resource.descriptions.where.not(description: nil).each do |d|
          next if d.description.blank?

          dcs_resource.descriptions << Description.new(
            value: ActionController::Base.helpers.strip_tags(d.description),
            type: d.description_type_mapping_obj
          )
        end
      end

      def add_rights(dcs_resource)
        dcs_resource.rights_list = se_resource.rights.map do |r|
          Rights.new(
            value: r.rights,
            uri: to_uri(r.rights_uri)
          )
        end
      end

      def add_related_ids(dcs_resource)
        dcs_resource.related_identifiers = se_resource.related_identifiers.completed.map do |id|
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

      def add_alt_ids(dcs_resource)
        dcs_resource.alternate_identifiers = se_resource.alternate_identifiers.map do |id|
          AlternateIdentifier.new(
            value: id.alternate_identifier,
            type: id.alternate_identifier_type
          )
        end
      end

      def add_dates(dcs_resource)
        iss_dt = se_resource&.identifier&.datacite_issued_date
        avail_dt = se_resource&.identifier&.datacite_available_date

        dcs_resource.dates << Date.new(type: Datacite::Mapping::DateType::ISSUED, value: iss_dt) if iss_dt
        dcs_resource.dates << Date.new(type: Datacite::Mapping::DateType::AVAILABLE, value: avail_dt) if avail_dt
      end

      def add_subjects(dcs_resource)
        subjects = se_resource.subjects.map do |s|
          next unless s.subject.present?

          massaged_subject = if s.subject_scheme == 'fos'
                               "FOS: #{s.subject}"
                             else
                               s.subject
                             end
          if s.subject_scheme.present?
            Subject.new(value: massaged_subject, scheme: s.subject_scheme, scheme_uri: s.scheme_URI)
          else
            Subject.new(value: massaged_subject)
          end
        end.compact
        dcs_resource.subjects = subjects if subjects.any?
      end

      def add_contributors(dcs_resource, datacite_3: false)
        se_resource.contributors.completed.where.not(contributor_type: 'funder').each do |c|
          dcs_resource.contributors << Contributor.new(
            name: c.contributor_name,
            identifier: to_dcs_identifier(c.name_identifier),
            type: c.contributor_type_mapping_obj,
            affiliations: c.affiliations.map do |a|
              if a.ror_id && !datacite_3
                Affiliation.new(
                  identifier: a.ror_id,
                  identifier_scheme: 'ROR',
                  scheme_uri: to_uri('https://ror.org'),
                  value: a.smart_name
                )
              else
                Affiliation.new(value: a.smart_name)
              end
            end
          )
        end
      end

      def add_funding(dcs_resource, datacite_3: false)
        datacite_3 ? add_dc3_funders(dcs_resource) : add_funding_references(dcs_resource)
      end

      def sd_funder_contribs
        se_resource.contributors.completed.where(contributor_type: 'funder')
      end

      def add_dc3_funders(dcs_resource)
        sd_funder_contribs.each do |contrib|
          dcs_resource.descriptions << to_funding_desc(contrib)
          dcs_resource.contributors << to_dcs_funder(contrib)
        end
      end

      def add_funding_references(dcs_resource)
        dcs_resource.funding_references = sd_funder_contribs.map do |c|
          dmfi = if c.name_identifier_id.present?
                   FunderIdentifier.new(type: c.identifier_type_mapping_obj, value: c.name_identifier_id,
                                        scheme_uri: (if c.identifier_type == 'crossref_funder_id'
                                                       'https://www.crossref.org/services/funder-registry/'
                                                     end))
                 end

          FundingReference.new(
            name: c.contributor_name,
            identifier: dmfi,
            award_number: c.award_number
          )
        end
      end

      def to_dcs_funder(contrib)
        Contributor.new(
          name: contrib.contributor_name,
          identifier: to_dcs_identifier(contrib.name_identifier),
          type: ContributorType::FUNDER
        )
      end

      def to_funding_desc(contrib)
        award_num = contrib.award_number
        desc_text = "Data were created with funding from #{contrib.contributor_name}"
        desc_text << " under grant(s) #{award_num}." if award_num
        Description.new(type: DescriptionType::OTHER, value: desc_text)
      end

      def dcs_identifier_from(author_orcid)
        return unless author_orcid && !author_orcid.empty?

        NameIdentifier.new(
          scheme: 'ORCID',
          scheme_uri: 'http://orcid.org/',
          value: author_orcid
        )
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
