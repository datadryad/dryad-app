require 'stash/repo'
require 'stash/merritt/ezid'
require 'stash/merritt/package'
require 'stash/merritt/sword'
require 'stash/sword'
require 'stash_ezid/client'

module Stash
  module Merritt
    class Repository < Stash::Repo::Repository

      def tasks_for(resource_id:)
        [
            Ezid::EnsureIdentifierTask.new(resource_id: resource_id, ezid_client: ezid_client),
            Package::CreatePackageTask.new(resource_id: resource_id),
            Sword::SwordTask.new(sword_client: sword_client),
            Ezid::UpdateMetadataTask.new(ezid_client: ezid_client, url_helpers: url_helpers, resource_id: resource_id),
            Package::PackageCleanupTask.new(resource_id: resource_id)
        ]
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

      def sword_client
        @sword_client ||= begin
          repository = tenant.repository
          Stash::Sword::Client.new(
              logger: log,
              collection_uri: repository.endpoint,
              username: repository.username,
              password: repository.password
          )
        end
      end

    end
  end
end
