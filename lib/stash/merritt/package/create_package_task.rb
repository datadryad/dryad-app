require 'stash/repo'

module Stash
  module Merritt
    module Package
    class CreatePackageTask < Stash::Repo::Task
      attr_reader :resource_id

      def initialize(resource_id:)
        @resource_id = resource_id
      end

      # @return [SubmissionPackage] the package
      def exec(doi)
        SubmissionPackage.new(resource_id: resource_id, doi: doi)
      end
    end
  end
end
end
