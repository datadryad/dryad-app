require 'spec_helper'

module StashEngine
  module Sword
    describe Packager do
      attr_reader :resource
      attr_reader :tenant
      attr_reader :url_helpers
      attr_reader :request_host
      attr_reader :request_port
      attr_reader :packager

      before(:each) do
        @resource = double(Resource)
        allow(resource).to receive(:id).and_return(17)
        @tenant = double(Tenant)
        @url_helpers = double(Module) # url_helpers is an anonymous module, apparently
        @request_host = 'stash.example.edu'
        @request_port = 443

        allow(Resource).to receive(:find).with(17).and_return(resource)

        @packager = Packager.new(
          resource: resource,
          tenant: tenant,
          url_helpers: url_helpers,
          request_host: request_host,
          request_port: request_port
        )
      end

      after(:each) do
        allow(Resource).to receive(:find).and_call_original
      end

      describe '#initialize' do
        it 'initializes' do
          expect(packager.resource).to be(resource)
          expect(packager.tenant).to be(tenant)
          expect(packager.url_helpers).to be(url_helpers)
          expect(packager.request_host).to be(request_host)
          expect(packager.request_port).to be(request_port)
        end
      end

      describe '#resource_title' do
        it 'is abstract' do
          expect { packager.resource_title }.to raise_error(NoMethodError)
        end
      end

      describe '#create_package' do
        it 'is abstract' do
          expect { packager.create_package }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
