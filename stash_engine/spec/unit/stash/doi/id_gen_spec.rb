require 'spec_helper'
require 'ostruct'
require_relative '../../../../lib/stash/doi/id_gen'
require_relative '../../../../lib/stash/doi/datacite_gen'

module Stash
  module Doi
    describe IdGen do

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

      # things to add
      # find resource
      # idg = Stash::Doi::IdGen.make_instance(resource: res)
      #
      #
      # Stash::Doi::IdGen.mint_id(resource: resource)
      #
      #
      #         @ezid_helper = instance_double(EzidGen)
      #         allow(EzidGen).to receive(:new).with(resource: resource).and_return(ezid_helper)
      #         allow(ezid_helper).to receive(:update_metadata)
      #         allow(ezid_helper).to receive(:'id_exists?').and_return(true)
      #         allow(ezid_helper).to receive(:reserve_id).and_return(identifier.identifier)
      #
      #
      describe :mint_id do
        it 'needs to allow minting for DataCite DOI' do
          identifier_str = 'doi:10.5072/1234-5678'
          path_to_landing = "/stash/#{identifier_str}"
          landing_page_url = URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s
          allow(@tenant).to receive(:tenant_id).and_return('dataone')
          allow(@tenant).to receive(:full_url).with(path_to_landing).and_return(landing_page_url)
          my_id = IdGen.mint_id(resource: resource)
          expect(my_id).to be_a_kind_of(String)
          expect(my_id.include?('/dryad.')).to be true
        end
      end

      describe :make_instance do
        it 'makes a DataCite instance' do
          inst = IdGen.make_instance(resource: resource)
          expect(inst).to be_instance_of(Stash::Doi::DataciteGen)
        end

        it 'makes an EZID instance' do
          allow(@tenant).to receive(:tenant_id).and_return('ucop')
          id_params = {
            provider: 'ezid',
            shoulder: 'doi:10.5072/FK2',
            account: 'gloob',
            password: 'gloob1',
            id_scheme: 'doi'
          }
          allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
          inst = IdGen.make_instance(resource: resource)
          expect(inst).to be_instance_of(Stash::Doi::EzidGen)
        end
      end

    end
  end
end
