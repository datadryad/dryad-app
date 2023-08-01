require 'ostruct'

module Stash
  module Doi
    describe EzidGen do
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

        @identifier = double(StashEngine::Identifier)
        allow(@identifier).to receive(:identifier).and_return('10.15146/R38675309')
        allow(resource).to receive(:identifier).and_return(@identifier)

        @identifier_str = 'doi:10.15146/R38675309'
        @url_helpers = double(Module)

        allow(@resource).to receive(:id).with(no_args).and_return(@resource_id)
        allow(@resource).to receive(:identifier_str).with(no_args).and_return(@identifier_str)

        path_to_landing = "/stash/#{identifier_str}"
        @landing_page_url = URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s
        allow(url_helpers).to receive(:show_path).with(identifier_str).and_return(path_to_landing)

        @tenant = double(StashEngine::Tenant)
        id_params = {
          provider: 'ezid',
          shoulder: 'doi:10.15146/R3',
          account: 'stash',
          password: '3cc9d3fbd9788148c6a32a1415fa673a',
          id_scheme: 'doi',
          owner: 'stash_admin'
        }
        allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:full_url).with(path_to_landing).and_return(landing_page_url)
        allow(resource).to receive(:tenant).and_return(tenant)

        @helper = EzidGen.new(resource: resource)
      end

      describe :mint_id do
        before(:each) do
          @ezid_client = instance_double(::Ezid::Client)

          allow(::Ezid::Client).to receive(:new)
            .with(host: 'ezid.cdlib.org', port: 80, user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
            .and_return(@ezid_client)
          allow(::Ezid::Client).to receive(:new)
            .with(host: 'ezid.cdlib.org', port: 443, user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
            .and_return(@ezid_client)

          @identifier = instance_double(::Ezid::MintIdentifierResponse)
          allow(@identifier).to receive(:id).and_return(@identifier_str)
          allow(@resource).to receive(:identifier).and_return(nil)
        end

        it 'creates a new identifier from Dryad prefix, not from EZID' do
          expect(@helper.mint_id).to start_with("doi:#{APP_CONFIG[:identifier_service][:prefix]}")
        end
      end

      describe :update_metadata do
        before(:each) do
          @dc4_xml = '<resource/>'
          @ezid_client = instance_double(::Ezid::Client)

          allow(::Ezid::Client).to receive(:new)
            .with(host: 'ezid.cdlib.org', port: 80, user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
            .and_return(@ezid_client)
          allow(::Ezid::Client).to receive(:new)
            .with(host: 'ezid.cdlib.org', port: 443, user: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
            .and_return(@ezid_client)
        end

        it 'updates the metadata and landing page' do
          expect(@ezid_client).to receive(:modify_identifier).with(
            @identifier_str,
            datacite: @dc4_xml,
            target: landing_page_url,
            status: 'public',
            owner: 'stash_admin'
          )
          expect(resource).to receive(:identifier_str).and_return(@identifier_str)
          helper.update_metadata(dc4_xml: @dc4_xml, landing_page_url: landing_page_url)
        end

        it 'raises an error when the status from Ezid does not equal 201' do
          ezid_error = ::Ezid::Error.new('Testing errors')
          # allow(ezid_error).to receive(:message).with(no_args).and_return('Testing errors')
          allow(@ezid_client).to receive(:modify_identifier).with(any_args).and_raise(ezid_error)
          dc = IdGen.make_instance(resource: @resource)
          expect { dc.update_metadata(dc4_xml: @dc4_xml, landing_page_url: 'http://example.com') }.to raise_error(Stash::Doi::EzidError)
        end
      end
    end
  end
end
