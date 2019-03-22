require 'spec_helper'
require 'stash/download/version'
require 'ostruct'

# a base class for version and file downloads, providing some basic functions
module Stash
  module Download
    describe 'Version' do

      describe 'merritt_async_download?' do

        before(:each) do
          @version = Version.new(controller_context: OpenStruct.new(response_body:  '',
                                                                    response: OpenStruct.new(headers: {})))
          @resource = StashEngine::Resource.create(tenant_id: 'dryad')
          allow(@resource).to receive(:merritt_protodomain_and_local_id).and_return(['www.example.com', 'ark:38u47/3847'])
          allow(@resource).to receive(:tenant).and_return('hi, not really used')

          @cli = double('client')
          allow(@cli).to receive(:get).with(anything, anything).and_return(OpenStruct.new(status_code: 200))

          my_http_client = double(Stash::Repo::HttpClient)

          allow(my_http_client).to receive(:client).and_return(@cli)
          allow(Stash::Repo::HttpClient).to receive(:new).and_return(my_http_client)
        end

        it 'handles status 200' do
          result = @version.merritt_async_download?(resource: @resource)
          expect(result).to be true
        end

        it 'handles status 406' do
          allow(@cli).to receive(:get).with(anything, anything).and_return(OpenStruct.new(status_code: 406))
          result = @version.merritt_async_download?(resource: @resource)
          expect(result).to be false
        end

        it 'handles Merritt being bad' do
          allow(@cli).to receive(:get).with(anything, anything).and_return(OpenStruct.new(status_code: 666))
          expect { @version.merritt_async_download?(resource: @resource) }.to raise_error(Stash::Download::MerrittResponseError)
        end
      end

      describe 'Version.merritt_friendly_async_url(resource:)' do
        before(:each) do
          @resource = StashEngine::Resource.create(tenant_id: 'dryad')
          allow(@resource).to receive(:merritt_protodomain_and_local_id).and_return(['www.example.com', 'ark:38u47/3847'])
          allow(@resource).to receive(:tenant).and_return('hi, not really used')
        end

        it 'generates the async download request url for merritt' do
          expect(Version.merritt_friendly_async_url(resource: @resource)).to eql('www.example.com/asyncd/ark:38u47/3847/1')
        end
      end

      describe '#download(resource:)' do
        before(:each) do
          @version = Version.new(controller_context: OpenStruct.new(response_body:  '',
                                                                    response: OpenStruct.new(headers: {})))
          @resource = StashEngine::Resource.create(tenant_id: 'dryad')
          allow(@resource).to receive(:tenant).and_return(OpenStruct.new(repository: OpenStruct.new(username: 'joe', password: 'blow')))
          allow(@resource).to receive(:merritt_producer_download_uri).and_return('http://merritt.example.com/a/download/url')
          allow(@version).to receive(:'merritt_async_download?').and_return(true)
          allow(@version).to receive(:stream_response).and_return('streaming')
          allow(StashEngine::CounterLogger).to receive(:version_download_hit).and_return(nil)
        end

        it 'detects an async download and yields to the block' do
          expect(@version.download(resource: @resource) { 'this would do async' }).to eql('this would do async')
        end

        it 'detects a normal download and starts' do
          allow(@version).to receive(:'merritt_async_download?').and_return(false)
          result = @version.download(resource: @resource) { 'this would do async' }
          expect(result).to eql('streaming')
        end
      end

      describe '#disposition_filename' do
        before(:each) do
          @identifier = create(:identifier)
          @resource = create(:resource, identifier_id: @identifier.id)
          @ds_version = create(:version, resource_id: @resource.id)
          @version = Version.new(controller_context: OpenStruct.new(response_body:  '',
                                                                    response: OpenStruct.new(headers: {})))
          @version.resource = @resource
        end

        it 'includes the version in the filename' do
          expect(@version.disposition_filename).to include("__v#{@ds_version.version}")
        end

        it 'includes content-disposition to have attachment with filename with zip' do
          expect(@version.disposition_filename).to match(/attachment; filename=".+zip"/)
        end

        it 'replaces colon and slashes with underscores' do
          m = @identifier.to_s.tr(':', '_').tr('/', '_')
          expect(@version.disposition_filename).to include(m)
        end
      end
    end
  end
end
