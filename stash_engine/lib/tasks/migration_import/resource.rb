module MigrationImport
  class Resource

    attr_reader :hash

    def initialize(hash:, identifier:)
      @hash = hash.with_indifferent_access
      @identifier = identifier
    end


    def import
      user_id = User.new(hash: hash[:user]).user_id

      save_hash = @hash.slice(*%w[created_at updated_at has_geolocation download_uri update_uri title publication_date
          accepted_agreement tenant_id])
      save_hash.merge!(identifier_id: @identifier.id, skip_datacite_update: true, skip_emails: true, user_id: user_id,
                       current_editor_id: user_id)
      save_hash.merge!(embargo_fields)
      # fields to add - current_resource_state_id, hold_for_peer_review, peer_review_end_date
      @resource_obj = StashEngine::Resource.create(save_hash)
      puts @resource_obj
    end

    def embargo_fields
      byebug
    end

  end
end