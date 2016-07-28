require 'datacite/mapping'
require 'stash_ezid/client'

module StashDatacite
  class TestImport

    def initialize(
        user_uid='scott.fisher-ucb@ucop.edu',
        xml_filename=File.join(StashDatacite::Engine.root, 'test', 'fixtures', 'datacite-example-full-v3.1.xml'),
        ezid_shoulder="doi:10.5072/FK2",
        ezid_account="apitest",
        ezid_password="apitest"
    )
      @user = StashEngine::User.find_by_uid(user_uid)
      @xml_str = File.read(xml_filename)

      ## a hack to fix some bad data in the xml files
      bad_contrib_regex = Regexp.new('<contributor contributorType="([^"]+)">\p{Space}*<contributor>([^<]+)</contributor>\p{Space}*</contributor>', Regexp::MULTILINE)
      good_contrib_replacement = "<contributor contributorType=\"\\1\">\n<contributorName>\\2</contributorName>\n</contributor>"
      @xml_str.gsub!(bad_contrib_regex, good_contrib_replacement)

      @m_resource = Datacite::Mapping::Resource.parse_xml(@xml_str, mapping: :nonvalidating)
      @ezid_client = StashEzid::Client.new(
          {shoulder: ezid_shoulder,
           account: ezid_account,
           password: ezid_password,
           id_scheme: 'doi',
           owner: 'apitest'
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
      byebug
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
      @m_resource.creators.each do |creator|
        lname, fname = extract_last_first(creator.name)
        name_ident = nil

        affil_ids = creator.affiliations.map{|i| get_or_create_affiliation(i)}

        # get/create name identifier
        unless creator.try(:identifier).blank?
          name_ident = NameIdentifier.find_or_create_by(name_identifier: creator.identifier.value,
                                                             name_identifier_scheme: creator.identifier.try(:scheme)) do |ni|
            ni.name_identifier_scheme = creator.identifier.try(:scheme)
            ni.scheme_URI = creator.identifier.try(:scheme_uri).try(:to_s)
          end
        end

        ar_creator = Creator.create(
            creator_first_name: fname,
            creator_last_name: lname,
            name_identifier_id: name_ident.try(:id),
            resource_id: @resource.id
        )
        ar_creator.affiliation_ids = affil_ids
      end
    end

    def add_titles
      @m_resource.titles.each do |t|
        Title.create(title: t.value, title_type_friendly: t.try(:type).try(:value), resource_id: @resource.id)
      end
    end

    def add_publisher
      unless @m_resource.publisher.blank?
        Publisher.create(publisher: @m_resource.publisher, resource_id: @resource.id)
      end
    end

    def add_publication_year
      unless @m_resource.try(:publication_year).blank?
        PublicationYear.create(publication_year: @m_resource.publication_year, resource_id: @resource.id)
      end
    end

    def add_subjects
      @m_resource.subjects.each do |s|
        subj = Subject.find_or_create_by(subject: s.value) do |sub|
          sub.subject_scheme = s.try(:scheme)
          sub.scheme_URI = s.try(:scheme_uri).try(:to_s)
        end
        ResourcesSubjects.create(resource_id: @resource.id, subject_id: subj.id)
      end
    end

    def add_contributors
      @m_resource.contributors.each do |c|
        affil_ids = c.affiliations.map{|i| get_or_create_affiliation(i)}
        name_ident = nil

        # get/create name identifier
        unless c.try(:identifier).blank?
          name_ident = NameIdentifier.find_or_create_by(name_identifier: c.identifier.value,
                                                        name_identifier_scheme: c.identifier.try(:scheme)) do |ni|
            ni.name_identifier_scheme = c.identifier.try(:scheme)
            ni.scheme_URI = c.identifier.try(:scheme_uri).try(:to_s)
          end
        end

        ar_contributor = Contributor.create(
            contributor_name: c.name,
            contributor_type_friendly: c.try(:type).try(:value),
            name_identifier_id: name_ident.try(:id),
            resource_id: @resource.id
        )
        ar_contributor.affiliation_ids = affil_ids
      end
    end

    def add_dates
      @m_resource.dates.each do |d|
        DataciteDate.create(date: d.value, date_type_friendly: d.try(:type).try(:value), resource_id: @resource.id)
      end
    end

    def add_language
      unless @m_resource.language.blank?
        Language.create(language: @m_resource.language, resource_id: @resource.id )
      end
    end

    def add_resource_type
      unless @m_resource.resource_type.blank?
        ResourceType.create(resource_type_friendly: @m_resource.resource_type.try(:resource_type_general).try(:value),
                            resource_id: @resource.id)
      end
    end

    def add_alternate_identifiers
      @m_resource.alternate_identifiers.each do |ai|
        AlternateIdentifier.create(alternate_identifier: ai.value, alternate_identifier_type: ai.type, resource_id: @resource.id)
      end
    end

    def add_related_identifiers
      @m_resource.related_identifiers.each do |ri|
        RelatedIdentifier.create(related_identifier:                ri.value,
                                 related_identifier_type_friendly:  ri.try(:identifier_type).try(:value),
                                 relation_type_friendly:            ri.try(:relation_type).try(:value),
                                 related_metadata_scheme:           ri.try(:related_metadata_scheme),
                                 scheme_URI:                        ri.try(:scheme_uri).try(:to_s),
                                 scheme_type:                       ri.try(:scheme_type),
                                 resource_id:                       @resource.id)
      end
    end

    def add_sizes
      @m_resource.sizes.each do |s|
        Size.create(size: s, resource_id: @resource.id)
      end
    end

    def add_formats
      @m_resource.formats.each do |fmt|
        Format.create(format: fmt, resource_id: @resource.id)
      end
    end

    def add_version
      unless @m_resource.version.blank?
        Version.create(version: @m_resource.version, resource_id: @resource.id)
      end
    end

    def add_rights
      @m_resource.rights_list.each do |r|
        Right.create(rights: r.try(:value), rights_uri: r.try(:uri).try(:to_s), resource_id: @resource.id)
      end
    end

    def add_descriptions
      @m_resource.descriptions.each do |d|
        des = Description.create(description: d.value, description_type_datacite: d.try(:type).try(:value), resource_id: @resource.id)
      end
      # TODO, need more secret sauce here for reading the special Other description types that mean something in dash.
    end

    def add_geolocations
      set_geolocation = false
      @m_resource.geo_locations.each do |geo|
        unless geo.place.blank?
          GeolocationPlace.create(geo_location_place: geo.place, resource_id: @resource.id)
          set_geolocation = true
        end

        unless geo.try(:point).blank?
          GeolocationPoint.create(latitude: geo.point.latitude, longitude: geo.point.longitude, resource_id: @resource.id)
          set_geolocation = true
        end

        unless geo.try(:box).blank?
          GeolocationBox.create(
                            ne_latitude: geo.box.north_latitude,
                            ne_longitude: geo.box.east_longitude,
                            sw_latitude: geo.box.south_latitude,
                            sw_longitude: geo.box.west_longitude,
                            resource_id: @resource.id
          )
          set_geolocation
        end
        if set_geolocation
          @resource.geolocation = true
          @resource.save!
        end
      end


    end


    private
    def extract_last_first(name_w_comma)
      name_w_comma.split(',', 2).map { |i| i.strip }
    end

    # gets or creates an affiliation and returns the affiliation id or nil
    def get_or_create_affiliation(affil_name_string)
      affils = Affiliation.where("short_name = ? or long_name = ?", affil_name_string, affil_name_string)
      affil_no = nil
      if affils.blank?
        unless affil_name_string.blank?
          affil_no = Affiliation.create(long_name: affil_name_string).id
        end
      else
        affil_no = affils.first.id
      end
      affil_no
    end
  end

  class TestImportDir
    def initialize(path_string = '/Users/scottfisher/dataone', uid = 'scott.fisher-ucb@ucop.edu')
      @uid = uid
      @xml_fns = Dir.glob(File.join(path_string, '**/mrt-datacite.xml'))
    end

    def import_xml
      @xml_fns.each do |fn|
        resource = StashDatacite::TestImport.new(@uid, fn)
        resource.populate_tables
      end
    end
  end
end
