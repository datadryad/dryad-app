require 'stash/repo'

module Stash
  module Merritt
    module Package
      class PackageCleanupTask < Stash::Repo::Task
        attr_reader :resource_id

        def initialize(resource_id:)
          @resource_id = resource_id
        end

        # @param package [SubmissionPackage] the package to clean up
        # @return [SubmissionPackage] the package
        def exec(package)
          package.cleanup
          package
        end
      end
    end
  end
end
