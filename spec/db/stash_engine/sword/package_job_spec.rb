require 'db_spec_helper'

require 'fileutils'

module StashEngine
  module Sword
    describe PackageJob do
      attr_reader :packager

      before(:each) do
        @packager = instance_double(Packager)
      end

      describe '#create_package' do
        it 'delegates to the Packager' do
          package = instance_double(Package)
          expect(packager).to receive(:create_package).and_return(package)
          job = PackageJob.new(packager)
          expect(job.create_package).to be(package)
        end
      end

      describe '#package_async' do
        attr_reader :logger

        RESOURCE_ID = 17
        TENANT_ID = 'dataone'

        before(:each) do
          immediate_executor = Concurrent::ImmediateExecutor.new
          allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)

          resource = double(Resource)
          allow(resource).to receive(:id).and_return(RESOURCE_ID)
          allow(packager).to receive(:resource).and_return(resource)

          tenant = double(Tenant)
          allow(tenant).to receive(:tenant_id).and_return(TENANT_ID)
          allow(packager).to receive(:tenant).and_return(tenant)

          @logger = instance_double(Logger)
          allow(logger).to receive(:debug)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)
          allow(logger).to receive(:error)

          @rails_logger = Rails.logger
          Rails.logger = logger
        end

        after(:each) do
          allow(Concurrent).to receive(:global_io_executor).and_call_original
          Rails.logger = @rails_logger
        end

        it 'delegates to the Packager' do
          package = instance_double(Package)
          allow(package).to receive(:zipfile).and_return('example.zip')
          expect(packager).to receive(:create_package).and_return(package)
          result = PackageJob.package_async(packager).value!
          expect(result).to be(package)
        end

        it 'logs success' do
          package = instance_double(Package)
          allow(package).to receive(:zipfile).and_return('example.zip')
          allow(packager).to receive(:create_package).and_return(package)
          expect(logger).to receive(:info).with(/PackageJob.*#{RESOURCE_ID}.*#{TENANT_ID}.*example\.zip.*/)
          PackageJob.package_async(packager).value!
        end

        it 'logs failure' do
          allow(packager).to receive(:create_package).and_raise(IOError)
          expect(logger).to receive(:warn).with(/PackageJob.*#{RESOURCE_ID}.*#{TENANT_ID}.*IOError.*/)
          expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
        end
      end
    end
  end
end
