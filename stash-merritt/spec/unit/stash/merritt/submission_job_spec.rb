require 'spec_helper'

module Stash
  module Merritt
    describe SubmissionJob do
      attr_reader :logger
      attr_reader :landing_page_url
      attr_reader :tenant
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

        @landing_page_url = URI::HTTPS.build(host: 'stash.example.edu', path: '/stash/doi:10.123/456').to_s

        @tenant = double(StashEngine::Tenant)
        sword_params = {
          collection_uri: 'http://example.edu/sword/example',
          username: 'elvis',
          password: 'presley'
        }.freeze
        id_params = {
          provider: 'ezid',
          shoulder: 'doi:10.15146/R3',
          account: 'stash',
          password: '3cc9d3fbd9788148c6a32a1415fa673a',
          id_scheme: 'doi',
          owner: 'stash_admin'
        }
        allow(tenant).to receive(:identifier_service).and_return(id_params.to_ostruct)
        allow(tenant).to receive(:sword_params).and_return(sword_params)
        allow(tenant).to receive(:id).and_return('example_u')
        allow(tenant).to receive(:full_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }

        @resource_id = 37
        @resource = double(StashEngine::Resource)
        allow(StashEngine::Resource).to receive(:find).with(resource_id).and_return(resource)
        allow(resource).to receive(:identifier_str).and_return('doi:10.123/456')
        allow(resource).to receive(:update_uri).and_return(nil)
        allow(resource).to receive(:tenant).and_return(tenant)
        allow(resource).to receive(:tenant_id).and_return('example_u')
        allow(resource).to receive(:skip_datacite_update).and_return(false)

        identifier = double(StashEngine::Identifier)
        allow(identifier).to receive(:identifier_type).and_return('DOI')
        allow(identifier).to receive(:identifier).and_return('10.123/456')
        allow(resource).to receive(:identifier).and_return(identifier)

        @url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        allow(url_helpers).to(receive(:show_path)) { |identifier_str| "/stash/#{identifier_str}" }

        @package = instance_double(ZipPackage)
        allow(ZipPackage).to receive(:new).with(resource: resource).and_return(package)
        allow(package).to receive(:dc4_xml)
        allow(package).to receive(:cleanup!)

        @sword_helper = instance_double(SwordHelper)
        allow(SwordHelper).to receive(:new).with(package: package, logger: logger).and_return(sword_helper)
        allow(sword_helper).to receive(:submit!)

        @job = SubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
        allow(@job).to receive(:id_helper).and_return(OpenStruct.new(ensure_identifier: 'xxx'))

        allow(Stash::Repo::Repository).to receive(:'hold_submissions?').and_return(false)
      end

      after(:each) do
        Rails.logger = @rails_logger
      end

      describe :submit! do

        before(:each) do
          allow(resource).to receive(:upload_type).and_return(:files)
        end

        describe 'create' do

          it "doesn't submit the package if holding submissions for a restart" do
            allow(Stash::Repo::Repository).to receive(:'hold_submissions?').and_return(true)
            expect(sword_helper).not_to receive(:submit!)
            job.submit!
          end

          it "doesn't reprocess previously submitted items (as shown by processing queue state)" do
            # not having working database and activerecord in these tests sucks
            allow(StashEngine::RepoQueueState).to receive(:where).and_return([1, 2])
            allow(StashEngine::RepoQueueState).to receive(:latest)
              .and_return({ 'present?': true, state: { 'enqueued?': true }.to_ostruct }.to_ostruct)
            # Stash::Repo::Repository.update_repo_queue_state(resource_id: resource_id, state: 'processing')
            # Stash::Repo::Repository.update_repo_queue_state(resource_id: resource_id, state: 'enqueued')
            expect(sword_helper).not_to receive(:submit!)
            job.submit!
          end

          it 'submits the package' do
            expect(sword_helper).to receive(:submit!)
            job.submit!
          end

          it 'does not update datacite if flagged to skip updates' do
            allow(resource).to receive(:skip_datacite_update).and_return(true)
            dc4_xml = '<resource/>'
            expect(ezid_helper).not_to receive(:update_metadata).with(dc4_xml: dc4_xml, landing_page_url: landing_page_url)
            job.submit!
          end

          it 'cleans up the package' do
            expect(package).to receive(:cleanup!)
            job.submit!
          end

          it 'returns a result' do
            result = job.submit!
            expect(result).to be_a(Stash::Repo::SubmissionResult)
            expect(result.success?).to be_truthy
          end
        end

        describe 'update' do
          before(:each) do
            expect(resource).to receive(:update_uri).and_return('http://example.sword.edu/doi:10.123/456')
          end

          it 'submits the package' do
            expect(sword_helper).to receive(:submit!)
            job.submit!
          end

          it 'cleans up the package' do
            expect(package).to receive(:cleanup!)
            job.submit!
          end

          it 'returns a result' do
            result = job.submit!
            expect(result).to be_a(Stash::Repo::SubmissionResult)
            expect(result.success?).to be_truthy
          end
        end

        describe 'error handling' do
          it 'fails on a bad resource ID' do
            bad_id = resource_id * 17
            job = SubmissionJob.new(resource_id: bad_id, url_helpers: url_helpers)
            allow(StashEngine::Resource).to receive(:find).with(bad_id).and_raise(ActiveRecord::RecordNotFound)
            expect(job.submit!.error).to be_a(ActiveRecord::RecordNotFound)
          end

          it 'fails on a SWORD submission error' do
            expect(sword_helper).to receive(:submit!).and_raise(RestClient::RequestFailed)
            expect(job.submit!.error).to be_a(RestClient::RequestFailed)
          end

          it 'fails on a package cleanup error' do
            expect(package).to receive(:cleanup!).and_raise(Errno::ENOENT)
            expect(job.submit!.error).to be_a(Errno::ENOENT)
          end
        end
      end
    end
  end
end
