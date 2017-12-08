module StashApi
  class Dataset

    def initialize(identifier:)
      id_type, iden = identifier.split(':', 2)
      @se_identifier = StashEngine::Identifier.where(identifier_type: id_type, identifier: iden).first
    end

    def last_version
      res_id = @se_identifier.resources.joins(:stash_version).order('version DESC').first.id
      Version.new(resource_id: res_id)
    end

    def metadata
      {
          id: @se_identifier.to_s,
          storage_size: @se_identifier.storage_size
      }.merge(last_version.metadata)
    end
  end
end