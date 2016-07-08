require 'datacite/mapping'
require 'stash_ezid/client'

module StashDatacite
  class TestImport

    # TODO: the enums are all lowercase, is this really how we want them?

    def initialize(
        user_uid='scott.fisher-ucb@ucop.edu',
        xml_filename=File.join(StashDatacite::Engine.root, 'test', 'fixtures', 'datacite-example-full-v3.1.xml'),
        ezid_shoulder="doi:10.5072/FK2",
        ezid_account="apitest",
        ezid_password="apitest"
    )
      @user = StashEngine::User.find_by_uid(user_uid)
      @xml_str = File.read(xml_filename)
      @m_resource = Datacite::Mapping::Resource.parse_xml(@xml_str)
      @ezid_client = StashEzid::Client.new(
          {shoulder: ezid_shoulder,
           account: ezid_account,
           password: ezid_password,
           coowners: [''],
           id_scheme: 'doi'
          })
    end

    def datacite_mapping
      @m_resource
    end

    def populate_tables

      set_up_resource
      #TODO: also need to add additional values to resource: geolocation (0/1), download_uri, update_uri

      add_creators
      add_titles
      add_publisher
      add_publication_year
      add_subjects
      add_contributors
      add_dates
      add_language
      add_resource_type
      add_alternate_identifiers
      add_related_identifiers
      add_sizes
      add_formats
      add_version
      add_rights
      add_descriptions
      add_geolocations
    end

    def set_up_resource
      # commented this out since testing 'in_progress' dataset instead
      #get a new ezid id ready and create identifier in DB
      #minted_id = @ezid_client.mint_id # retured like "doi:10.5072/FK2NK3C276"
      #ezid_id_type, ezid_id_body = minted_id.split(':', 2)
      #ezid_id_type.upcase!
      #stash_id = StashEngine::Identifier.create(identifier: ezid_id_body, identifier_type: ezid_id_type)

      # create resource with resource_state, identifier (DOI) and version for a user
      @resource = StashEngine::Resource.create(user_id: @user.id)
      #@resource = StashEngine::Resource.create(user_id: @user.id, identifier_id: stash_id.id)
      #resource_state = StashEngine::ResourceState.create(user_id: @user.id, resource_state: 'published', resource_id: @resource.id)
      resource_state = StashEngine::ResourceState.create(user_id: @user.id, resource_state: 'in_progress', resource_id: @resource.id)
      @resource.update(current_resource_state_id: resource_state.id)
      #StashEngine::Version.create(version: 1, resource_id: @resource.id)
    end

    def add_creators
      @m_resource.creators.each do |c|
        lname, fname = extract_last_first(c.name)
        name_identifier_id = nil
        orcid_id = nil
        affil_no = get_or_create_affiliation(c.affiliations.try(:first))

        # set/create orcid or name identifier (other than orcid?)
        unless c.try(:identifier).blank?
          # TODO: check into this since it's weird that ORCIDs are handled differently than other name identifiers
          if c.identifier.scheme == 'ORCID'
            orcid_id = c.identifier.value unless c.identifier.value.blank?
          else
            name_id = NameIdentifier.find_or_create_by(name_identifier: c.identifier.value) do |ni|
              ni.name_identifier_scheme = c.identifier.try(:scheme)
              ni.scheme_URI = c.identifier.try(:scheme_uri).try(:to_s)
            end
            name_identifier_id = name_id.id
          end
        end

        # TODO: affiliation 0-n in datacite, but 0-1 here
        # add creator with the
        Creator.create(
            creator_first_name: fname,
            creator_last_name: lname,
            name_identifier_id: name_identifier_id,
            orcid_id: orcid_id,
            resource_id: @resource.id,
            affliation_id: affil_no
        )
      end
    end

    def add_titles
      @m_resource.titles.each do |t|
        title_type = 'main'
        unless t.type.nil?
          title_type = t.type.value.downcase
        end
        Title.create(title: t.value, title_type: title_type, resource_id: @resource.id)
      end
    end

    def add_publisher
      unless @m_resource.publisher.blank?
        Publisher.create(publisher: @m_resource.publisher, resource_id: @resource.id)
      end
    end

    def add_publication_year
      unless @m_resource.publication_year.blank?
        PublicationYear.create(publication_year: @m_resource.publication_year, resource_id: @resource.id)
      end
    end

    def add_subjects
      @m_resource.subjects.each do |s|
        subj = Subject.find_or_create_by(subject: s.value) do |sub|
          sub.subject_scheme = s.scheme
          sub.scheme_URI = s.try(:scheme_uri).try(:to_s)
        end
        ResourcesSubjects.create(resource_id: @resource.id, subject_id: subj.id)
      end
    end

    def add_contributors
      @m_resource.contributors.each do |c|
        affil_no = get_or_create_affiliation(c.affiliations.try(:first))
        name_identifier_id = nil

        unless c.try(:identifier).blank?
          name_id = NameIdentifier.find_or_create_by(name_identifier: c.identifier.value) do |ni|
            ni.name_identifier_scheme = c.identifier.try(:scheme)
            ni.scheme_URI = c.identifier.try(:scheme_uri).try(:to_s)
          end
          name_identifier_id = name_id.id
        end

        # TODO: affiliation 0-n in datacite, but 0-1 here
        Contributor.create(
            contributor_name: c.name,
            contributor_type: c.try(:type).try(:value).try(:downcase),
            name_identifier_id: name_identifier_id,
            affliation_id: affil_no,
            resource_id: @resource.id
        )
      end
    end

    def add_dates
      @m_resource.dates.each do |d|
        DataciteDate.create(date: d.value, date_type: d.type.value.downcase)
      end
    end

    def add_language
      # TODO: We don't seem to have a language in the database
      #unless @m_resource.language.blank?
      #
      #end
    end

    def add_resource_type
      unless @m_resource.resource_type.blank?
        ResourceType.create(resource_type: @m_resource.resource_type.try(:resource_type_general).try(:value),
                            resource_id: @resource.id)
      end
    end

    def add_alternate_identifiers
      # TODO: are we ignoring alternate identifiers?  I don't see a table in the database.
    end

    def add_related_identifiers
      @m_resource.related_identifiers.each do |ri|
        related_iden_type_id = RelatedIdentifierType.find_by_related_identifier_type(ri.identifier_type.value)
        relation_type_id = RelationType.find_by_relation_type(ri.relation_type.value)
        # TODO: we are losing some data since relation_type table has properties that belong to related identifiers
        # instead

        RelatedIdentifier.create(
            related_identifier:           ri.value,
            related_identifier_type_id:   related_iden_type_id,
            relation_type_id:             relation_type_id,
            resource_id:                  @resource.id
        )
      end
    end

    def add_sizes
      @m_resource.sizes.each do |s|
        Size.create(size: s, resource_id: @resource.id)
      end
    end

    def add_formats
      # TODO: formats seems to be missing from database
    end

    def add_version
      unless @m_resource.version.blank?
        Version.create(version: @m_resource.version)
      end
    end

    def add_rights
      @m_resource.rights_list.each do |r|
        Right.create(rights: r.value, rights_uri: r.uri)
      end
    end

    def add_descriptions
      @m_resource.descriptions.each do |d|
        Description.create(description: d.value, description_type: d.type.value.downcase, resource_id: @resource.id)
      end
    end

    def add_geolocations
      # TODO:  It seems as though we're missing the parent geolocation (spatial region or named place) element from
      # DataCite 3.1 and are just focusing on the points, boxes and place elements 0..1 that are dependent elements

      # TODO: is the db place name the place element or the top level description? Also datacite_mapping doesn't give both

      @m_resource.geo_locations.each do |geo|
        unless geo.place.blank?
          GeolocationPlace.create(geo_location_place: geo.place, resource_id: @resource.id)
        end

        unless geo.try(:point).blank?
          GeolocationPoint.create(latitude: geo.point.latitude, longitude: geo.point.longitude, resource_id: @resource.id)
        end

        unless geo.try(:box).blank?
          GeolocationBox.create(
                            ne_latitude: geo.box.north_latitude,
                            ne_longitude: geo.box.east_longitude,
                            sw_latitude: geo.box.south_latitude,
                            sw_longitude: geo.box.west_longitude,
                            resource_id: @resource.id
          )
        end
      end


    end


    private
    def extract_last_first(name_w_comma)
      name_w_comma.split(',', 2).map { |i| i.strip }
    end

    # gets or creates an affiliation and returns the affiliation id or nil
    def get_or_create_affiliation(affil_name_string)
      affils = Affliation.where("short_name = ? or long_name = ?", affil_name_string, affil_name_string)
      affil_no = nil
      if affils.blank?
        unless affil_name_string.blank?
          affil_no = Affliation.create(long_name: affil_name_string).id
        end
      else
        affil_no = affils.first.id
      end
      affil_no
    end
  end
end
