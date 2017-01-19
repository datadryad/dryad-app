require 'spec_helper'
require 'ostruct'

module Stash
  module Merritt
    module Ezid
      describe EzidHelper do
        attr_reader :resource_id
        attr_reader :resource
        attr_reader :identifier_str
        attr_reader :landing_page_url
        attr_reader :helper
        attr_reader :url_helpers
        attr_reader :tenant

        before(:each) do
          @resource_id = 17
          @resource = double(StashEngine::Resource)
          allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)

          @identifier_str = 'doi:10.15146/R38675309'
          @url_helpers = double(Module)
          @landing_page_url = "http://stash.example.edu/stash/#{identifier_str}"
          allow(url_helpers).to receive(:show_path).with(identifier_str).and_return(landing_page_url)

          @tenant = double(StashEngine::Tenant)
          id_params = {
            shoulder: 'doi:10.15146/R3',
            owner: 'stash_admin',
            account: 'stash',
            password: '3cc9d3fbd9788148c6a32a1415fa673a',
            id_scheme: 'doi'
          }
          allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
          allow(tenant).to receive(:tenant_id).and_return('dataone')
          allow(resource).to receive(:tenant).and_return(tenant)

          @helper = EzidHelper.new(resource: resource, url_helpers: url_helpers)
        end

        describe :ensure_identifier do
          it 'returns an existing identifier without bothering EZID' do
            expect(resource).to receive(:identifier_str).and_return(identifier_str)
            expect(::Ezid::Client).not_to receive(:new)
            expect(helper.ensure_identifier).to eq(identifier_str)
          end

          it 'mints and assigns a new identifier if none is present' do
            identifier = instance_double(::Ezid::MintIdentifierResponse)
            allow(identifier).to receive(:id).and_return(identifier_str)

            ezid_client = instance_double(::Ezid::Client)
            allow(::Ezid::Client).to receive(:new)
              .with(user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
              .and_return(ezid_client)

            expect(resource).to receive(:identifier_str).and_return(nil)
            expect(ezid_client).to receive(:mint_identifier)
              .with('doi:10.15146/R3', status: 'reserved', profile: 'datacite')
              .and_return(identifier)
            expect(resource).to receive(:ensure_identifier).with(identifier_str)
            expect(helper.ensure_identifier).to eq(identifier_str)
          end
        end

        describe :update_metadata do
          it 'updates the metadata and landing page' do
            dc3_xml = '<resource/>'

            ezid_client = instance_double(::Ezid::Client)
            allow(::Ezid::Client).to receive(:new)
              .with(user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
              .and_return(ezid_client)

            expect(ezid_client).to receive(:modify_identifier).with(
              identifier_str,
              datacite: dc3_xml,
              target: landing_page_url,
              status: 'public',
              owner: 'stash_admin'
            )

            expect(resource).to receive(:identifier_str).and_return(identifier_str)
            helper.update_metadata(dc3_xml)
          end
        end
      end
    end
  end
end
