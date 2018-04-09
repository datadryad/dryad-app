module StashApi
  # takes a dataset hash, parses it out and saves it to the appropriate places in the database
  class DatasetParser
    def initialize(hash: nil, id: nil, user:)
      @hash = hash
      @id = id
      @user = user
      @resource = @id.in_progress_resource
      @previous_orcids = {}
    end

    def parse
      if @resource.nil?
        create_dataset
      else
        clear_previous_metadata
      end
      @resource.update(title: @hash['title'])
      # probably want to clear and re-add authors for data updates
      @hash[:authors].each { |author| add_author(json_author: author) }
      StashDatacite::Description.create(description: @hash[:abstract], description_type: 'abstract', resource_id: @resource.id)
      @resource.identifier
    end

    private

    def clear_previous_metadata
      @resource.update(title: '')
      @resource.authors.each { |au| @previous_orcids["#{au.author_first_name} #{au.author_last_name}"] = au.author_orcid }
      @resource.authors.destroy_all
      @resource.descriptions.type_abstract.destroy_all
    end

    def create_dataset
      @resource = StashEngine::Resource.create(
        user_id: @user.id, current_editor_id: @user.id, identifier_id: nil, title: '', tenant_id: @user.tenant_id
      )
      # creating a new resource automatically creates an in-progress status and a version
      my_id = StashEngine.repository.mint_id(resource: @resource)
      id_type, id_text = my_id.split(':', 2)
      ident = StashEngine::Identifier.create(identifier: id_text, identifier_type: id_type.upcase)
      ident.resources << @resource
      add_default_values # for license, publisher, resource type
    end

    def add_author(json_author: author)
      a = StashEngine::Author.create(
        author_first_name: json_author[:firstName],
        author_last_name: json_author[:lastName],
        author_email: json_author[:email],
        author_orcid: @previous_orcids["#{json_author[:firstName]} #{json_author[:lastName]}"],
        resource_id: @resource.id
      )
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
      license = StashEngine::License.by_id(@resource.tenant.default_license)
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
