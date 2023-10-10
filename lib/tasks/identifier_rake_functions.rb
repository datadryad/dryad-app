# :nocov:
module Tasks
  module IdentifierRakeFunctions
    def self.update_identifiers
      resources = StashEngine::Resource.joins('LEFT JOIN stash_engine_identifiers ON ' \
                                              'stash_engine_resources.identifier_id = stash_engine_identifiers.id')
        .where('stash_engine_identifiers.id IS NULL OR stash_engine_identifiers.identifier IS NULL')

      puts "There are #{resources.count} stash_engine_resources without stash_engine_identifiers"

      resources.each do |resource|
        next if resource&.identifier&.indentifier # double-check just in case something has changed since query

        puts "Generating identifier for stash_engine_resource #{resource.id}: #{resource.title}"
        make_identifier(resource: resource)
      end
    end

    def self.make_identifier(resource:)
      my_id = Stash::Doi::IdGen.mint_id(resource: resource)
      id_type, id_text = my_id.split(':', 2)
      if resource.identifier.nil?
        # create record for identifier and add it to resource
        db_id_obj = StashEngine::Identifier.create!(identifier: id_text, identifier_type: id_type.upcase)
        resource.update!(identifier_id: db_id_obj.id)
        return
      end
      resource.identifier.update!(identifier: id_text, identifier_type: id_type.upcase)
    end
  end
end
# :nocov:
