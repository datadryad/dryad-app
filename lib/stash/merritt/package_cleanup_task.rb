require 'stash/repo'

module Stash
  module Merritt
    class PackageCleanupTask < Stash::Repo::Task
      attr_reader :resource_id

      def initialize(resource_id:)
        @resource_id = resource_id
      end

      # @return [Package] the package
      def exec(package)
        package.cleanup
        package
      end
    end
  end
end
