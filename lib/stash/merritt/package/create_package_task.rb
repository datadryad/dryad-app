require 'stash/repo'

module Stash
  module Merritt
    module Package
      class CreatePackageTask < Stash::Repo::Task
        attr_reader :resource_id
        attr_reader :tenant

        def initialize(resource_id:, tenant:)
          @resource_id = resource_id
          @tenant = tenant
        end

        def to_s
          "#{super}: resource #{resource_id}, tenant: #{tenant.tenant_id}"
        end

        # @return [SubmissionPackage] the package
        def exec(*)
          SubmissionPackage.new(resource_id: resource_id, tenant: tenant)
        end
      end
    end
  end
end
