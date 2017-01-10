require 'stash/repo'

module Stash
  module Merritt
    class PackageTask < Stash::Repo::Task
      attr_reader :resource_id

      def initialize(resource_id:)
        @resource_id = resource_id
      end

      # @return [Package] the package
      def exec(_doi)
        Package.new(resource_id: resource_id)
      end
    end
  end
end
