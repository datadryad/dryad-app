require 'spec_helper'
require 'ostruct'

module Stash
  module Merritt
    module Ezid
      describe EnsureIdentifierTask do
        attr_reader :resource_id
        attr_reader :resource
        attr_reader :task
        attr_reader :tenant

        before(:each) do
          @resource_id = 17
          @resource    = double(StashEngine::Resource)
          allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)

          @tenant   = double(StashEngine::Tenant)
          id_params = {
            shoulder:  'doi:10.15146/R3',
            account:   'stash',
            password:  '3cc9d3fbd9788148c6a32a1415fa673a',
            id_scheme: 'doi'
          }
          allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
          allow(tenant).to receive(:tenant_id).and_return('dataone')
          allow(resource).to receive(:tenant).and_return(tenant)

          @task = EnsureIdentifierTask.new(resource_id: resource_id)
        end

        describe :exec do
          it 'returns an existing identifier without bothering EZID' do
            identifier_str = 'doi:123/456'
            expect(resource).to receive(:identifier_str).and_return(identifier_str)
            expect(::Ezid::Client).not_to receive(:new)
            expect(task.exec).to eq(identifier_str)
          end

          it 'mints and assigns a new identifier if none is present' do
            new_identifier_str = 'doi:10.15146/R38675309'
            identifier         = instance_double(::Ezid::MintIdentifierResponse)
            allow(identifier).to receive(:id).and_return(new_identifier_str)

            ezid_client = instance_double(::Ezid::Client)
            allow(::Ezid::Client).to receive(:new)
              .with(user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
              .and_return(ezid_client)

            expect(resource).to receive(:identifier_str).and_return(nil)
            expect(ezid_client).to receive(:mint_identifier)
              .with('doi:10.15146/R3', status: 'reserved', profile: 'datacite')
              .and_return(identifier)
            expect(resource).to receive(:ensure_identifier).with(new_identifier_str)
            expect(task.exec).to eq(new_identifier_str)
          end
        end
      end
    end
  end
end
