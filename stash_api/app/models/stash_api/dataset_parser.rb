module StashApi
  # takes a dataset hash, parses it out and saves it to the appropriate places in the database
  class DatasetParser

    TO_PARSE = %w[Funders Methods UsageNotes Keywords RelatedWorks Locations TemporalCoverages].freeze

    # If  id_string is set, then populate the desired (doi) into the identifier in format like doi:xxxxx/yyyyy for new dataset.
    # the id is a stash_engine_identifier object and indicates an already existing object.  May not set both.
    # On final submission, updating the DOI may fail if it's wrong, unauthorized or not in the right format.
    def initialize(hash: nil, id: nil, user:, id_string: nil)
      raise 'You may not specify an identifier string with an existing identifier' if id && id_string
      @id_string = id_string
      @hash = hash
      @id = id
      @user = user
      @resource = @id.in_progress_resource if @id
      @previous_orcids = {}
    end

    # this is the basic required metadata
    def parse
      if @resource.nil?
        create_dataset(doi_string: @id_string) # @id string will be nil if not specified, so minted, otherwise to be created
      else
        clear_previous_metadata
      end
      user_id = @hash['userId'] || @user.id
      @resource.update(
        title: @hash['title'],
        user_id: user_id,
        current_editor_id: user_id,
        skip_datacite_update: @hash['skipDataciteUpdate'] || false,
        skip_emails: @hash['skipEmails'] || false,
        preserve_curation_status: @hash['preserveCurationStatus'] || false,
        loosen_validation: @hash['loosenValidation'] || false
      )
      # probably want to clear and re-add authors for data updates
      @hash[:authors]&.each { |author| add_author(json_author: author) }
      StashDatacite::Description.create(description: @hash[:abstract], description_type: 'abstract', resource_id: @resource.id)
      TO_PARSE.each { |item| dynamic_parse(my_class: item) }
      @resource.identifier
    end

    private

    def dynamic_parse(my_class:)
      c = Object.const_get("StashApi::DatasetParser::#{my_class}")
      parse_instance = c.new(resource: @resource, hash: @hash)
      parse_instance.parse
    end

    def clear_previous_metadata
      @resource.update(title: '')
      @resource.authors.each { |au| @previous_orcids["#{au.author_first_name} #{au.author_last_name}"] = au.author_orcid }
      @resource.authors.destroy_all
      @resource.descriptions.type_abstract.destroy_all
    end

    def create_dataset(doi_string: nil)
      # resource needs to be created early, since minting an ID is based on the resource's tenant, add identifier afterward
      @resource = StashEngine::Resource.create(
        user_id: @user.id, current_editor_id: @user.id, title: '', tenant_id: @user.tenant_id
      )

      my_id = doi_string || Stash::Doi::IdGen.mint_id(resource: @resource)
      id_type, id_text = my_id.split(':', 2)
      ident = StashEngine::Identifier.create(identifier: id_text, identifier_type: id_type.upcase)

      ident.resources << @resource # add resource to identifier
      add_default_values # for license, publisher, resource type
    end

    def add_author(json_author: author)
      a = StashEngine::Author.new(
        author_first_name: json_author[:firstName],
        author_last_name: json_author[:lastName],
        author_email: json_author[:email],
        author_orcid: @previous_orcids["#{json_author[:firstName]} #{json_author[:lastName]}"],
        resource_id: @resource.id
      )
      a.save(validate: false) # we can validate on submission, keeps from saving otherwise
      a.affiliation_by_name(json_author[:affiliation]) unless json_author[:affiliation].blank?
    end

    # certain things need setting up on initialization based on tenant
    def add_default_values
      ensure_license
      ensure_publisher
      ensure_resource_type
    end

    def ensure_license
      return unless @resource.rights.blank?
      license = StashEngine::License.by_id(@resource.identifier.license_id)
      @resource.rights.create(rights: license[:name], rights_uri: license[:uri])
    end

    def ensure_publisher
      return unless @resource.publisher.blank?
      publisher = StashDatacite::Publisher.where(resource_id: @resource.id).first
      StashDatacite::Publisher.create(publisher: @resource.tenant.short_name, resource_id: @resource.id) unless publisher
    end

    def ensure_resource_type
      return unless @resource.resource_type.blank?
      StashDatacite::ResourceType.create(resource_type_general: 'dataset', resource_type: 'dataset', resource_id: @resource.id)
    end

  end
end
