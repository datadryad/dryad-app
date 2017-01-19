require 'spec_helper'

module Stash
  module Merritt
    module Package
      describe CreatePackageTask do

        attr_reader :resource_id
        attr_reader :tenant
        attr_reader :task

        before(:each) do
          @resource_id = 17
          @tenant = double(StashEngine::Tenant)
          allow(tenant).to receive(:tenant_id).and_return('dataone')
          allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)
          @task = CreatePackageTask.new(resource_id: resource_id)
        end

        describe :exec do
          it 'returns a new package' do
            pkg = instance_double(SubmissionPackage)
            expect(SubmissionPackage).to receive(:new).with(resource_id: resource_id).and_return(pkg)
            expect(task.exec).to eq(pkg)
          end
        end
      end
    end
  end
end
