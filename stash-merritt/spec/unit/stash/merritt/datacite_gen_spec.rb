require 'spec_helper'
require 'ostruct'
require_relative '../../../../lib/stash/merritt/id_gen'

module Stash
  module Merritt
    describe DataciteGen do
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

        @identifier_str = 'doi:10.5072/1234-5678'
        @url_helpers = double(Module)

        path_to_landing = "/stash/#{identifier_str}"
        @landing_page_url = URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s
        allow(url_helpers).to receive(:show_path).with(identifier_str).and_return(path_to_landing)

        @tenant = double(StashEngine::Tenant)
        id_params = {
          provider: 'datacite',
          prefix: '10.5072',
          account: 'stash',
          password: '3cc9d3fbd9788148c6a32a1415fa673a',
          sandbox: true
        }
        allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:full_url).with(path_to_landing).and_return(landing_page_url)
        allow(resource).to receive(:tenant).and_return(tenant)
        allow(resource).to receive(:identifier_str).and_return(@identifier_str)

        # allow(StashEngine).to receive(:app).and_return({ ezid: { host: 'ezid.cdlib.org', port: 80 } }.to_ostruct)

        @helper = DataciteGen.new(resource: resource)
      end

      describe :mint_id do
        it 'mints a new identifier' do
          datac = instance_double(Cirneco::DataCenter)
          allow(datac).to receive(:encode_doi).with('10.5072').and_return('10.5072/1234-5678')

          allow(Cirneco::DataCenter).to receive(:new)
            .with(prefix: '10.5072', username: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a')
            .and_return(datac)

          expect(helper.mint_id).to eq(identifier_str)
        end
      end

      describe :update_metadata do
        it 'updates the metadata and landing page' do
          dc4_xml = '<resource/>'

          # took off instance_double
          dc_gen = Stash::Merritt::DataciteGen.new(resource: resource)

          allow(dc_gen).to receive(:post_metadata)
            .with(dc4_xml, username: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a', sandbox: true)
            .and_return({ status: 201 }.to_ostruct)

          allow(dc_gen).to receive(:put_doi)
            .with('10.5072/1234-5678', username: 'stash', password: '3cc9d3fbd9788148c6a32a1415fa673a', sandbox: true, url: 'http://example.com')
            .and_return({ status: 201 }.to_ostruct)

          expect(dc_gen
            .update_metadata(dc4_xml: dc4_xml, landing_page_url: 'http://example.com'))
            .to eq(nil)

          # make sure it selects this class in the IdGen parent class
          expect(IdGen.make_instance(resource: resource).class).to eq(Stash::Merritt::DataciteGen)
        end
      end
    end
  end
end
