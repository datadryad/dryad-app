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
          Ezid::EzidHelper.new(resource_id: resource_id),
          Package::CreatePackageTask.new(resource_id: resource_id),
          Sword::SwordTask.new,
          Ezid::UpdateMetadataTask.new(ezid_client: ezid_client, url_helpers: url_helpers, resource_id: resource_id),
          Package::PackageCleanupTask.new(resource_id: resource_id)
        ]
      end
    end
  end
end
