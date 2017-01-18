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
          @task = CreatePackageTask.new(resource_id: resource_id, tenant: tenant)
        end

        describe :to_s do
          it 'describes the task' do
            task_str = task.to_s
            expect(task_str).to include(CreatePackageTask.to_s)
            expect(task_str).to include(resource_id.to_s)
            expect(task_str).to include('dataone')
          end
        end

        describe :exec do
          it 'returns a new package' do
            pkg = instance_double(SubmissionPackage)
            expect(SubmissionPackage).to receive(:new).with(resource_id: resource_id, tenant: tenant).and_return(pkg)
            expect(task.exec).to eq(pkg)
          end
        end
      end
    end
  end
end
