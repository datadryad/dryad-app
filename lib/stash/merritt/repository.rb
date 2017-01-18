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
          # TODO: should we pass the tenant around, or get it from the resource?
          Ezid::EnsureIdentifierTask.new(resource_id: resource_id, tenant: tenant),
          Package::CreatePackageTask.new(resource_id: resource_id, tenant: tenant),
          Sword::SwordTask.new(sword_client: sword_client),
          Ezid::UpdateMetadataTask.new(ezid_client: ezid_client, url_helpers: url_helpers, resource_id: resource_id),
          Package::PackageCleanupTask.new(resource_id: resource_id)
        ]
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
