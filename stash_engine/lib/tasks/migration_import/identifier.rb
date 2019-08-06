module MigrationImport
  class Identifier

    attr_reader :hash

    def initialize(hash:)
      @hash = hash.with_indifferent_access
    end


    def import
      # handle myself
      save_hash = @hash.slice(*%w[identifier identifier_type storage_size created_at updated_at])
      @id_obj = StashEngine::Identifier.create(save_hash)
      puts @id_obj
      @hash[:resources].each do |json_resource|
        @resource_obj = Resource.new(hash: json_resource, identifier: @id_obj)
        @resource_obj.import
      end
    end

  end
end