module StashApi
  # takes a dataset hash, parses it out and saves it to the appropriate places in the database
  class DatasetParser

    TO_PARSE = %w[Funders Methods UsageNotes Keywords FieldOfScience RelatedWorks Locations TemporalCoverages].freeze
    INTERNAL_DATA_FIELDS = %w[publicationISSN publicationName manuscriptNumber].freeze

    # If  id_string is set, then populate the desired (doi) into the identifier in format like doi:xxxxx/yyyyy for new dataset.
    # the id is a stash_engine_identifier object and indicates an already existing object.  May not set both.
    # On final submission, updating the DOI may fail if it's wrong, unauthorized or not in the right format.
    def initialize(user:, hash: nil, id: nil, id_string: nil)
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
      clear_previous_metadata
      owning_user_id = establish_owning_user_id
      owning_user = StashEngine::User.find(owning_user_id)
      user_note = "Created by API user, assigned ownership to #{owning_user&.name} (#{owning_user_id})"
      @resource.curation_activities << StashEngine::CurationActivity.create(status: @resource.current_curation_status || 'in_progress',
                                                                            user_id: @user.id,
                                                                            resource_id: @resource.id,
                                                                            note: user_note)

      @resource.update(
        title: remove_html(@hash['title']),
        user_id: owning_user_id,
        current_editor_id: owning_user_id,
        skip_datacite_update: @hash['skipDataciteUpdate'] || false,
        skip_emails: @hash['skipEmails'] || false,
        preserve_curation_status: @hash['preserveCurationStatus'] || false,
        loosen_validation: @hash['loosenValidation'] || false
      )

      @hash[:authors]&.each { |author| add_author(json_author: author) }
      StashDatacite::Description.create(description: @hash[:abstract], description_type: 'abstract', resource_id: @resource.id)
      TO_PARSE.each { |item| dynamic_parse(my_class: item) }
      @resource.identifier.payment_type = @hash['paymentType']
      @resource.identifier.payment_id = @hash['paymentId']
      @resource.identifier.waiver_basis = @hash['waiverBasis']
      parse_internal_data
      @resource.identifier.save
      @resource.identifier
    end
    # rubocop:enable

    private

    def remove_html(in_string)
      ActionView::Base.full_sanitizer.sanitize(in_string)
    end

    def establish_owning_user_id
      if @hash['userId']&.to_s&.match(/\d{4}-\d{4}-\d{4}-\d{3,4}X?/)
        owning_user_id_from_orcid
      elsif @hash['userId'].to_s&.match(/\A\d+\z/)
        # If the userId is an integer, treat it as the id of an existing user
        begin
          StashEngine::User.find(@hash['userId']).id
        rescue ActiveRecord::RecordNotFound
          raise 'The userId is not known to Dryad. Please supply the id of an existing Dryad user, or an orcid matching an author of the dataset.'
        end
      else
        # otherwise, give ownership to the API user
        @user.id
      end
    end

    def owning_user_id_from_orcid
      # Since userId is specified as an orcid, determine whether we know this user;
      # otherwise, create them
      owning_user = StashEngine::User.where(orcid: @hash['userId'])&.first
      if owning_user.nil?
        # check if any authors listed in the dataset have this orcid
        found_author = nil
        @hash['authors'].each do |a|
          found_author = a if a['orcid']&.match(@hash['userId'])
        end
        raise 'The userId orcid is not known to Dryad. Please supply a matching orcid in the dataset author list.' unless found_author

        owning_user = StashEngine::User.create(orcid: @hash['userId'],
                                               first_name: found_author['firstName'],
                                               last_name: found_author['lastName'],
                                               email: found_author['email'])
      end
      owning_user.id
    end

    def parse_internal_data
      if @hash['publicationName'].present? && @hash['publicationISSN'].blank?
        @hash['publicationISSN'] = StashEngine::Journal.find_by_title(@hash['publicationName'])&.issn
      end

      INTERNAL_DATA_FIELDS.each do |int_field|
        StashEngine::InternalDatum.create(data_type: int_field, stash_identifier: @resource.identifier, value: @hash[int_field]) if @hash[int_field]
      end
    end

    def dynamic_parse(my_class:)
      c = Object.const_get("StashApi::DatasetParser::#{my_class}")
      parse_instance = c.new(resource: @resource, hash: @hash)
      parse_instance.parse
    end

    def clear_previous_metadata
      if @resource.nil?
        create_dataset(doi_string: @id_string) # @id string will be nil if not specified, so minted, otherwise to be created
      else
        @resource.update(title: '')
        @resource.authors.each { |au| @previous_orcids["#{au.author_first_name} #{au.author_last_name}"] = au.author_orcid }
        @resource.authors.destroy_all
        @resource.descriptions.type_abstract.destroy_all
      end
    end

    def create_dataset(doi_string: nil)
      # Resource needs to be created early, since minting an ID is based on the resource's tenant, add identifier afterward
      # The user_id is initially set to the user that made the API call, though ownership may be changed
      # to a different user in the `parse` method based on metadata sent in the API call.
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
        author_email: parse_email(json_author[:email]),
        author_orcid: json_author[:orcid] || @previous_orcids["#{json_author[:firstName]} #{json_author[:lastName]}"],
        resource_id: @resource.id,
        author_order: json_author[:order] || nil
      )
      # If the affiliation was provided, prefer the ROR id over a textual name.
      if json_author[:affiliationROR].present?
        a.affiliation = StashDatacite::Affiliation.from_ror_id(ror_id: json_author[:affiliationROR])
      elsif json_author[:affiliationISNI].present?
        afis = StashDatacite::Affiliation.from_isni_id(isni_id: json_author[:affiliationISNI])
        a.affiliation = afis
      elsif json_author[:affiliation].present?
        a.affiliation = StashDatacite::Affiliation.from_long_name(long_name: json_author[:affiliation], check_ror: false)
      end

      a.save(validate: false) # we can validate on submission, keeps from saving otherwise
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
      return if publisher

      StashDatacite::Publisher.create(publisher: 'Dryad', resource_id: @resource.id) if @resource.tenant
    end

    def ensure_resource_type
      return unless @resource.resource_type.blank?

      StashDatacite::ResourceType.create(resource_type_general: 'dataset', resource_type: 'dataset', resource_id: @resource.id)
    end

    private def parse_email(email_string)
      # is it an email with display name and brackets like "Bob Jones <bob.jones@example.org>"-- then suck email out
      matches = email_string&.match(/<(.+?@.+?)>/)
      return matches[1] if matches

      # if comma or semicolon
      parts = email_string&.split(/[;,]/)
      return parts[0]&.strip if parts && parts.length > 1

      # otherwise, pass through unchanged
      email_string
    end

  end
end
