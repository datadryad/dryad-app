module Tasks
  module MigrationImport
    class Identifier

      attr_reader :hash, :ar_identifier

      def initialize(hash:)
        @hash = hash.with_indifferent_access
      end

      def import
        # handle myself
        save_hash = @hash.slice('identifier', 'identifier_type', 'storage_size', 'created_at', 'updated_at')
        @ar_identifier = StashEngine::Identifier.create(save_hash)

        # delegate to resources
        @hash[:resources].each do |json_resource|
          @resource_obj = Resource.new(hash: json_resource, ar_identifier: @ar_identifier)
          @resource_obj.import
        end
        add_orcid_invitations
        @ar_identifier.update_column(:latest_resource_id, @ar_identifier&.resources&.last&.id)
        @ar_identifier.update_search_words!
      end

      def add_orcid_invitations
        @hash[:orcid_invitations].each do |json_invitation|
          my_hash = json_invitation.slice('email', 'first_name', 'last_name', 'secret', 'orcid', 'invited_at', 'accepted_at')
          @ar_identifier.orcid_invitations << StashEngine::OrcidInvitation.create(my_hash)
        end
      end

    end
  end
end
