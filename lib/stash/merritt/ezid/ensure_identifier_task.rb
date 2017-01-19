require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class EnsureIdentifierTask < Stash::Repo::Task
        attr_reader :resource_id

        def initialize(resource_id:)
          @resource_id = resource_id
        end

        # @return [String] the identifier (DOI, ARK, or URN)
        def exec
          resource = StashEngine::Resource.find(resource_id)
          identifier_str = resource.identifier_str
          return identifier_str if identifier_str

          ezid_client = ezid_client_for(resource.tenant)
          new_identifier_str = ezid_client.mint_id
          resource.ensure_identifier(new_identifier_str)
          new_identifier_str
        end

        private

        def ezid_client_for(tenant)
          id_params = tenant.identifier_service
          StashEzid::Client.new(
            shoulder: id_params.shoulder,
            account: id_params.account,
            password: id_params.password,
            owner: id_params.owner,
            id_scheme: id_params.scheme
          )
        end

      end
    end
  end
end
