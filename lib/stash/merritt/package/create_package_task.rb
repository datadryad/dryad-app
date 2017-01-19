require 'stash/repo'

module Stash
  module Merritt
    module Package
      class CreatePackageTask < Stash::Repo::Task
        attr_reader :resource_id

        def initialize(resource_id:)
          @resource_id = resource_id
        end

        def to_s
          "#{super}: resource #{resource_id}"
        end

        # @return [SubmissionPackage] the package
        def exec(*)
          SubmissionPackage.new(resource_id: resource_id)
        end
      end
    end
  end
end
