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
        attr_reader :resource

        RESOURCE_ID = 17
        TENANT_ID = 'dataone'

        before(:each) do
          immediate_executor = Concurrent::ImmediateExecutor.new
          allow(Concurrent).to receive(:global_io_executor).and_return(immediate_executor)

          @resource = double(Resource)
          allow(resource).to receive(:id).and_return(RESOURCE_ID)
          allow(packager).to receive(:resource).and_return(resource)
          allow(packager).to receive(:resource_title).and_return('An Account of a Very Odd Monstrous Calf')

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

        describe 'failure logging and email' do
          attr_reader :title
          attr_reader :request_host
          attr_reader :request_port

          before(:each) do
            @title = 'An Account of a Very Odd Monstrous Calf'
            allow(resource).to receive(:title).and_return(title)

            @request_host = 'stash.example.edu'
            @request_port = 80

            allow(packager).to receive(:create_package).and_raise(IOError)
            allow(packager).to receive(:request_host).and_return(request_host)
            allow(packager).to receive(:request_port).and_return(request_port)

            allow(resource).to receive(:current_state=)

            msg = double(ActionMailer::MessageDelivery)
            allow(msg).to receive(:deliver_now)

            allow(UserMailer).to receive(:error_report).and_return(msg)
            allow(UserMailer).to receive(:update_failed).and_return(msg)
            allow(UserMailer).to receive(:create_failed).and_return(msg)
          end

          describe 'on create' do
            before(:each) do
              allow(resource).to receive(:update_uri).and_return(nil)
            end

            it 'sends "create failed"' do
              msg = double(ActionMailer::MessageDelivery)
              expect(msg).to receive(:deliver_now)

              expect(UserMailer).to receive(:create_failed).with(resource, title, request_host, request_port, kind_of(IOError)).and_return(msg)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'logs a failure' do
              expect(logger).to receive(:warn).with(/PackageJob.*#{RESOURCE_ID}.*#{TENANT_ID}.*IOError.*/)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'sets the resource state' do
              expect(resource).to receive(:current_state=).with('error')
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'sends an error report' do
              msg = double(ActionMailer::MessageDelivery)
              expect(msg).to receive(:deliver_now)

              expect(UserMailer).to receive(:error_report).with(resource, title, kind_of(IOError)).and_return(msg)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end
          end

          describe 'on update' do
            before(:each) do
              allow(resource).to receive(:update_uri).and_return('https://repo.example.edu/10.123/456')
            end

            it 'sends "update failed"' do
              msg = double(ActionMailer::MessageDelivery)
              expect(msg).to receive(:deliver_now)

              expect(UserMailer).to receive(:update_failed).with(resource, title, request_host, request_port, kind_of(IOError)).and_return(msg)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'logs a failure' do
              expect(logger).to receive(:warn).with(/PackageJob.*#{RESOURCE_ID}.*#{TENANT_ID}.*IOError.*/)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'sets the resource state' do
              expect(resource).to receive(:current_state=).with('error')
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end

            it 'sends an error report' do
              msg = double(ActionMailer::MessageDelivery)
              expect(msg).to receive(:deliver_now)

              expect(UserMailer).to receive(:error_report).with(resource, title, kind_of(IOError)).and_return(msg)
              expect { PackageJob.package_async(packager).value! }.to raise_error(IOError)
            end
          end

        end
      end
    end
  end
end
