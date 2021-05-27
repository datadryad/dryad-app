require 'datacite/mapping'
require 'stash/wrapper'
require 'time'

# rubocop:disable Naming/AccessorMethodName

# Borrowed from stash_migrator
module StashDatacite
  class ResourceBuilder
    DESCRIPTION_TYPE = Datacite::Mapping::DescriptionType

    attr_reader :user_id, :tenant_id, :dcs_resource, :stash_files, :upload_time

    def initialize(user_id:, dcs_resource:, stash_files:, upload_date:, tenant_id: 'dataone')
      @user_id = user_id
      @dcs_resource = ResourceBuilder.dcs_resource(dcs_resource)
      @stash_files = ResourceBuilder.stash_files(stash_files)
      @upload_time = upload_date.to_time
      @tenant_id = tenant_id
    end

    def self.dcs_resource(dcs_resource)
      return dcs_resource if dcs_resource.is_a?(Datacite::Mapping::Resource)
      return dcs_resource if dcs_resource.to_s =~ /InstanceDouble\(Datacite::Mapping::Resource\)/ # For RSpec tests

      raise ArgumentError, "dcs_resource does not appear to be a Datacite::Mapping::Resource: #{dcs_resource || 'nil'}"
    end

    def self.stash_files(stash_files)
      return stash_files if stash_files.all? do |file|
        file.is_a?(Stash::Wrapper::StashFile) ||
        file.to_s =~ /InstanceDouble\(Stash::Wrapper::StashFile\)/ # For RSpec tests
      end

      raise ArgumentError, "stash_files does not appear to be an array of Stash::Wrapper::StashFile objects: #{stash_files || 'nil'}"
    end

    def build
      populate_se_resource!
    end

    private

    def se_resource
      @se_resource ||= StashEngine::Resource.create(user_id: user_id, tenant_id: tenant_id)
    end

    def se_resource_id
      se_resource.id
    end

    # rubocop:disable Metrics/AbcSize
    def populate_se_resource!
      set_sd_identifier(dcs_resource.identifier)
      stash_files.each { |stash_file| add_stash_file(stash_file) }
      dcs_resource.contributors.each { |dcs_creator| add_se_author(dcs_creator) }
      dcs_resource.titles.each { |dcs_title| add_se_title(dcs_title) }
      set_sd_publisher(dcs_resource.publisher)
      set_sd_pubyear(dcs_resource.publication_year)
      dcs_resource.subjects.each { |dcs_subject| add_sd_subject(dcs_subject) }
      dcs_resource.contributors.each { |dcs_contributor| add_sd_contributor(dcs_contributor) }
      dcs_resource.dates.each { |dcs_date| add_sd_date(dcs_date) }
      set_sd_language(dcs_resource.language)
      set_sd_resource_type(dcs_resource.resource_type)
      dcs_resource.alternate_identifiers.each { |dcs_alternate_ident| add_sd_alternate_ident(dcs_alternate_ident) }
      dcs_resource.related_identifiers.each { |dcs_related_ident| add_sd_related_ident(dcs_related_ident) }
      dcs_resource.sizes.each { |dcs_size| add_sd_size(dcs_size) }
      dcs_resource.formats.each { |dcs_format| add_sd_format(dcs_format) }
      set_sd_version(dcs_resource.version)
      dcs_resource.rights_list.each { |dcs_rights| add_sd_rights(dcs_rights) }
      dcs_resource.descriptions.each { |dcs_description| add_sd_description(dcs_description) }
      dcs_resource.geo_locations.each { |dcs_geo_location| add_sd_geo_location(dcs_geo_location) }
      dcs_resource.funding_references.each { |dcs_funding_reference| add_funding(dcs_funding_reference) }
      se_resource.save!
      se_resource
    end
    # rubocop:enable Metrics/AbcSize

    def set_sd_identifier(dcs_identifier)
      return unless dcs_identifier

      se_resource.identifier_id = StashEngine::Identifier.create(
        identifier: dcs_identifier.value && dcs_identifier.value.strip,
        identifier_type: dcs_identifier.identifier_type
      ).id
    end

    def add_stash_file(stash_file)
      StashEngine::DataFile.create(
        resource_id: se_resource_id,
        upload_file_name: stash_file.pathname,
        upload_content_type: stash_file.mime_type.to_s,
        upload_file_size: stash_file.size_bytes,
        upload_updated_at: upload_time,
        file_state: 'created'
      )
    end

    def add_se_author(dcs_creator)
      last_name, first_name = extract_last_first(dcs_creator.name)
      email_address = email_from(dcs_creator.identifier) || "#{first_name}.#{last_name}@example.edu".gsub(/\s +/, '_')
      se_author = StashEngine::Author.create(
        author_first_name: first_name,
        author_last_name: last_name,
        author_email: email_address,
        author_orcid: orcid_from(dcs_creator.identifier),
        resource_id: se_resource_id
      )
      se_author.affiliation_ids = dcs_creator.affiliations.map { |affiliation_obj| sd_affiliation_id_for(affiliation_obj) }
      se_author
    end

    def add_se_title(dcs_title)
      # now throwing away datacite info on title and only using one main title in stash_engine.resource
      return if dcs_title.type

      se_resource.title = dcs_title && dcs_title.value.strip
    end

    def set_sd_publisher(dcs_publisher)
      Publisher.create(publisher: dcs_publisher&.value, resource_id: se_resource_id) unless dcs_publisher.blank?
    end

    def set_sd_pubyear(dcs_publication_year)
      return if dcs_publication_year.blank?

      PublicationYear.create(publication_year: dcs_publication_year, resource_id: se_resource_id)
    end

    def add_sd_subject(dcs_subject)
      sd_subject_id = sd_subject_id_for(dcs_subject)
      ResourcesSubjects.create(resource_id: se_resource_id, subject_id: sd_subject_id)
    end

    def add_sd_contributor(dcs_contributor)
      contributor_type = dcs_contributor.type
      sd_contributor = Contributor.create(
        contributor_name: dcs_contributor.name,
        contributor_type_friendly: (contributor_type.value if contributor_type),
        name_identifier_id: sd_name_identifier_id_for(dcs_contributor.identifier),
        resource_id: se_resource_id
      )
      sd_contributor.affiliation_ids = dcs_contributor.affiliations.map { |affiliation_obj| sd_affiliation_id_for(affiliation_obj) }
      sd_contributor
    end

    def add_sd_date(dcs_date)
      date_type = dcs_date.type
      DataciteDate.create(
        date: dcs_date.value && dcs_date.value.strip,
        date_type_friendly: (date_type.value if date_type),
        resource_id: se_resource_id
      )
    end

    def set_sd_language(dcs_language)
      return nil if dcs_language.blank?

      Language.create(language: dcs_language, resource_id: se_resource_id)
    end

    def set_sd_resource_type(dcs_resource_type)
      return nil unless dcs_resource_type

      dcs_resource_type_general = dcs_resource_type.resource_type_general
      dcs_resource_type_value = dcs_resource_type.value
      se_resource_type = dcs_resource_type_general.value.downcase
      resource_type_friendly = (ResourceType::ResourceTypesGeneralLimited.value?(se_resource_type) ? se_resource_type : 'other')

      ResourceType.create(
        resource_id: se_resource_id,
        resource_type_general: resource_type_friendly,
        resource_type: dcs_resource_type_value
      )

      # resource_type_friendly = (ResourceType::ResourceTypesGeneralLimited.value?(se_resource_type) ? se_resource_type : 'other')
      # ResourceType.create(
      #   resource_id: se_resource_id,
      #   resource_type_friendly: resource_type_friendly
      # )
    end

    def add_sd_alternate_ident(dcs_alternate_ident)
      AlternateIdentifier.create(
        alternate_identifier: dcs_alternate_ident.value && dcs_alternate_ident.value.strip,
        alternate_identifier_type: dcs_alternate_ident.type, # a string, not an enum
        resource_id: se_resource_id
      )
    end

    def add_sd_related_ident(dcs_related_ident)
      ident_type = dcs_related_ident.identifier_type
      rel_type = dcs_related_ident.relation_type
      scheme_uri = dcs_related_ident.scheme_uri
      RelatedIdentifier.create(
        related_identifier: dcs_related_ident.value && dcs_related_ident.value.strip,
        related_identifier_type_friendly: (ident_type.value if ident_type),
        relation_type_friendly: (rel_type.value if rel_type),
        related_metadata_scheme: dcs_related_ident.related_metadata_scheme,
        scheme_URI: (scheme_uri.to_s if scheme_uri),
        scheme_type: dcs_related_ident.scheme_type,
        resource_id: se_resource_id
      )
    end

    def add_sd_size(dcs_size)
      return if dcs_size.blank?

      Size.create(size: dcs_size, resource_id: se_resource_id)
    end

    def add_sd_format(dcs_format)
      return if dcs_format.blank?

      Format.create(format: dcs_format, resource_id: se_resource_id)
    end

    def set_sd_version(dcs_version)
      return if dcs_version.blank?

      Version.create(version: dcs_version, resource_id: se_resource_id)
    end

    def add_sd_rights(dcs_rights)
      rights_uri = dcs_rights.uri
      Right.create(
        rights: dcs_rights.value && dcs_rights.value.strip,
        rights_uri: (rights_uri.to_s if rights_uri),
        resource_id: se_resource_id
      )
    end

    def add_sd_description(dcs_description)
      desc_type = dcs_description.type
      if desc_type == DESCRIPTION_TYPE::OTHER && dcs_description.value.start_with?('Data were created with funding')
        add_sd_award_number(dcs_description.value)
      else
        Description.create(
          description: dcs_description.value && dcs_description.value.strip,
          description_type_friendly: (desc_type.value if desc_type),
          resource_id: se_resource_id
        )
      end
    end

    def add_sd_award_number(funding_desc_value)
      pat = /Data were created with funding from(.*)under grant\(?s?\)?(.*)\.?/m
      return unless (md = pat.match(funding_desc_value)) && md.size == 3

      contrib_name = md[1].gsub(/\s+/m, ' ').strip
      award_num = md[2].gsub(/\s+/m, ' ').sub(/.$/, '').strip

      matching_contrib = find_sd_funder(contrib_name)
      return unless matching_contrib

      matching_contrib.award_number = award_num
      matching_contrib.save!
    end

    def find_sd_funder(contrib_name)
      se_resource.contributors.where(
        "contributor_name LIKE ? and contributor_type='funder'",
        "%#{contrib_name.sub(/^[Tt]he ?/, '')}%"
      ).take
    end

    def add_sd_geo_location(dcs_geo_location)
      return unless dcs_geo_location.location?

      loc = Geolocation.create(resource_id: se_resource_id)
      add_sd_geo_location_place(loc, dcs_geo_location.place)
      add_sd_geo_location_point(loc, dcs_geo_location.point)
      add_sd_geo_location_box(loc, dcs_geo_location.box)
      loc.save
    end

    def add_sd_geo_location_place(se_geo_location, dcs_geo_location_place)
      return if dcs_geo_location_place.blank?

      se_place = GeolocationPlace.create(geo_location_place: dcs_geo_location_place)
      se_geo_location.place_id = se_place.id
    end

    def add_sd_geo_location_point(se_geo_location, dcs_geo_location_point)
      return unless dcs_geo_location_point

      se_point = GeolocationPoint.create(
        latitude: dcs_geo_location_point.latitude,
        longitude: dcs_geo_location_point.longitude
      )
      se_geo_location.point_id = se_point.id
    end

    def add_sd_geo_location_box(se_geo_location, dcs_geo_location_box)
      return unless dcs_geo_location_box

      se_box = GeolocationBox.create(
        sw_latitude: dcs_geo_location_box.south_latitude,
        sw_longitude: dcs_geo_location_box.west_longitude,
        ne_latitude: dcs_geo_location_box.north_latitude,
        ne_longitude: dcs_geo_location_box.east_longitude
      )
      se_geo_location.box_id = se_box.id
    end

    def add_funding(dcs_funding_reference)
      award_number = dcs_funding_reference.award_number
      Contributor.create(
        contributor_name: dcs_funding_reference.name,
        contributor_type: Datacite::Mapping::ContributorType::FUNDER.value.downcase,
        award_number: (award_number.value if award_number),
        resource_id: se_resource_id
      )
    end

    def extract_last_first(name_w_comma)
      name_w_comma.split(',', 2).map(&:strip)
    end

    def sd_affiliation_id_for(affiliation_obj)
      sd_affiliations = StashDatacite::Affiliation.where('short_name = ? or long_name = ?', affiliation_obj&.value, affiliation_obj&.value)
      return sd_affiliations.first.id unless sd_affiliations.empty?
      return nil if affiliation_obj.nil? || affiliation_obj.value.blank?

      StashDatacite::Affiliation.create(long_name: affiliation_obj&.value,
                                        ror_id: affiliation_obj&.identifier).id
    end

    def email_from(dcs_name_identifier)
      return unless dcs_name_identifier
      return unless dcs_name_identifier.scheme == 'email'

      value = dcs_name_identifier.value
      return unless value

      value.to_s.strip.sub('mailto:', '')
    end

    def orcid_from(dcs_name_identifier)
      return unless dcs_name_identifier
      return unless dcs_name_identifier.scheme == 'ORCID'

      value = dcs_name_identifier.value
      return unless value

      value.to_s.strip
    end

    def sd_name_identifier_id_for(dcs_name_identifier)
      return nil unless dcs_name_identifier

      scheme_uri = dcs_name_identifier.scheme_uri
      value = dcs_name_identifier.value
      sd_name_ident = StashDatacite::NameIdentifier.find_or_create_by(
        name_identifier: value.to_s.strip,
        name_identifier_scheme: dcs_name_identifier.scheme,
        scheme_URI: (scheme_uri.to_s if scheme_uri)
      )
      sd_name_ident.id
    end

    def sd_subject_id_for(dcs_subject)
      return nil unless dcs_subject

      scheme_uri = dcs_subject.scheme_uri
      StashDatacite::Subject.find_or_create_by(
        subject: dcs_subject.value.to_s.strip,
        subject_scheme: dcs_subject.scheme,
        scheme_URI: (scheme_uri.to_s if scheme_uri)
      ).id
    end
  end
end

# rubocop:enable Naming/AccessorMethodName
