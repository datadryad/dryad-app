require 'spec_helper'

module Stash
  module Merritt
    describe SubmissionJob do
      attr_reader :logger
      attr_reader :resource_id
      attr_reader :resource
      attr_reader :url_helpers
      attr_reader :ezid_helper
      attr_reader :package
      attr_reader :sword_helper
      attr_reader :job

      before(:each) do
        @logger = instance_double(Logger)
        allow(logger).to receive(:debug)
        allow(logger).to receive(:info)
        allow(logger).to receive(:warn)
        allow(logger).to receive(:error)

        @rails_logger = Rails.logger
        Rails.logger = logger

        @resource_id = 37
        @resource = double(StashEngine::Resource)
        allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)

        @url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        allow(url_helpers).to(receive(:show_path)) { |identifier| identifier }

        @ezid_helper = instance_double(EzidHelper)
        allow(EzidHelper).to receive(:new).with(resource: resource, url_helpers: url_helpers).and_return(ezid_helper)
        allow(ezid_helper).to receive(:ensure_identifier)
        allow(ezid_helper).to receive(:update_metadata)

        @package = instance_double(SubmissionPackage)
        allow(SubmissionPackage).to receive(:new).with(resource: resource).and_return(package)
        allow(package).to receive(:dc3_xml)
        allow(package).to receive(:cleanup!)

        @sword_helper = instance_double(SwordHelper)
        allow(SwordHelper).to receive(:new).with(package: package, logger: logger).and_return(sword_helper)
        allow(sword_helper).to receive(:submit!)

        @job = SubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
      end

      after(:each) do
        Rails.logger = @rails_logger
      end

      describe :submit! do
        it 'ensures an identifier' do
          expect(ezid_helper).to receive(:ensure_identifier)
          job.submit!
        end

        it 'submits the package' do
          expect(sword_helper).to receive(:submit!)
          job.submit!
        end

        it 'updates the metadata' do
          dc3_xml = '<resource/>'
          expect(package).to receive(:dc3_xml).and_return(dc3_xml)
          expect(ezid_helper).to receive(:update_metadata).with(dc3_xml: dc3_xml)
          job.submit!
        end

        it 'cleans up the package' do
          expect(package).to receive(:cleanup!)
          job.submit!
        end

        describe 'error handling' do
          it 'fails on a bad resource ID' do
            bad_id = resource_id * 17
            job = SubmissionJob.new(resource_id: bad_id, url_helpers: url_helpers)
            expect(StashEngine::Resource).to receive(:find).with(bad_id).and_raise(ActiveRecord::RecordNotFound)
            expect { job.submit! }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it 'fails on an ID minting error' do
            expect(ezid_helper).to receive(:ensure_identifier).and_raise(Ezid::NotAllowedError)
            expect { job.submit! }.to raise_error(Ezid::NotAllowedError)
          end

          it 'fails on a SWORD submission error' do
            expect(sword_helper).to receive(:submit!).and_raise(RestClient::RequestFailed)
            expect { job.submit! }.to raise_error(RestClient::RequestFailed)
          end

          it 'fails on a metadata update error' do
            expect(ezid_helper).to receive(:update_metadata).and_raise(Ezid::IdentifierNotFoundError)
            expect { job.submit! }.to raise_error(Ezid::IdentifierNotFoundError)
          end

          it 'fails on a package cleanup error' do
            expect(package).to receive(:cleanup!).and_raise(Errno::ENOENT)
            expect { job.submit! }.to raise_error(Errno::ENOENT)
          end
        end
      end
    end
  end
end
