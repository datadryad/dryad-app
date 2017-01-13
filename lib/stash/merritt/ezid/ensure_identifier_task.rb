require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class EnsureIdentifierTask < Stash::Repo::Task
        attr_reader :resource_id
        attr_reader :tenant

        # @param ezid_client [StashEzid::Client] the EZID client
        def initialize(resource_id:, tenant:)
          @resource_id = resource_id
          @tenant = tenant
        end

        # @return [String] the identifier (DOI, ARK, or URN)
        def exec(*)
          resource = StashEngine::Resource.find(resource_id)
          identifier_str = resource.identifier_str
          return identifier_str if identifier_str

          new_identifier_str = ezid_client.mint_id
          resource.ensure_identifier(new_identifier_str)
          new_identifier_str
        end

        def ezid_client
          @ezid_client ||= begin
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
end
