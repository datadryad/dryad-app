require 'byebug'

module Stash
  module Merritt
    describe Repository do
      include Mocks::Aws
      include Mocks::Datacite
      include Mocks::CurationActivity
      include Mocks::Salesforce

      attr_reader :resource
      attr_reader :identifier
      attr_reader :doi_value
      attr_reader :record_identifier
      attr_reader :repo
      attr_reader :rails_root
      attr_reader :public_system
      attr_reader :tenant

      before(:each) do
        mock_datacite!
        mock_aws!
        mock_salesforce!

        @rails_root = Dir.mktmpdir('rails_root')
        root_path = Pathname.new(rails_root)
        allow(Rails).to receive(:root).and_return(root_path)

        public_path = Pathname.new("#{rails_root}/public")
        allow(Rails).to receive(:public_path).and_return(public_path)

        @public_system = public_path.join('system').to_s
        FileUtils.mkdir_p(public_system)

        user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )

        repo_config = OpenStruct.new(
          domain: 'http://merritt.cdlib.org',
          endpoint: 'http://uc3-mrtsword-prd.cdlib.org:39001/mrtsword/collection/dataone_dash'
        )

        @tenant = double(StashEngine::Tenant)
        allow(@tenant).to receive(:tenant_id).and_return('dataone')
        allow(@tenant).to receive(:short_name).and_return('DataONE')
        allow(@tenant).to receive(:repository).and_return(repo_config)
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date,
          tenant_id: 'dataone'
        ).build
        @resource.current_state = 'processing'
        @resource.save
        @identifier = resource.identifier

        @doi_value = '10.15146/R3RG6G'
        expect(@resource.identifier_value).to eq(doi_value) # just to be sure

        @record_identifier = 'http://n2t.net/ark:/99999/fk43f5119b'

        url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        @repo = Repository.new(url_helpers: url_helpers)

        log = instance_double(Logger)
        allow(log).to receive(:debug)
        allow(Rails).to receive(:logger).and_return(log)
      end

      after(:each) do
        FileUtils.remove_dir(rails_root)
      end

      describe :create_submission_job do
        it 'creates a submission job' do
          url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
          repo = Repository.new(url_helpers: url_helpers, threads: 1)
          resource_id = 17
          job = repo.create_submission_job(resource_id: resource_id)
          expect(job).to be_a(SubmissionJob)
          expect(job.resource_id).to eq(resource_id)
          expect(job.url_helpers).to be(url_helpers)
        end
      end

      describe :download_uri_for do
        it 'determines the download URI' do
          expected_uri = 'https://merritt-test.example.org/d/ark%3A%2F99999%2Ffk43f5119b'
          actual_uri = repo.download_uri_for(record_identifier: record_identifier)
          expect(actual_uri).to eq(expected_uri)
        end
      end

      describe :update_uri_for do
        it 'determines the update URI' do
          expected_uri = 'https://merritt-test.example.org:39001/mrtsword/edit/cdl_dryaddev/doi%3A10.15146%2FR3RG6G'
          actual_uri = repo.update_uri_for(resource: resource, record_identifier: record_identifier)
          expect(actual_uri).to eq(expected_uri)
        end
      end

      describe :harvested do
        it 'sets the download URI, update URI, and status' do
          # Skip sending emails
          @resource.skip_emails = true
          @resource.save
          neuter_curation_callbacks!
          repo.harvested(identifier: @identifier, record_identifier: @record_identifier)
          @resource.reload
          expect(@resource.download_uri).to eq('https://merritt-test.example.org/d/ark%3A%2F99999%2Ffk43f5119b')
          expect(@resource.update_uri).to eq('https://merritt-test.example.org:39001/mrtsword/edit/cdl_dryaddev/doi%3A10.15146%2FR3RG6G')
          expect(@resource.current_state).to eq('submitted')
        end
      end

      describe :cleanup_files do
        it 'cleans up public/system files' do
          resource_public = "#{public_system}/#{resource.id}"
          FileUtils.mkdir(resource_public)
          stash_wrapper = "#{resource_public}/stash-wrapper.xml"
          some_other_file = "#{resource_public}/foo.bar"

          FileUtils.touch(stash_wrapper)
          FileUtils.touch(some_other_file)

          repo.cleanup_files(resource)

          [resource_public, stash_wrapper, some_other_file].each do |f|
            expect(File.exist?(f)).to be_falsey
          end
        end
      end
    end
  end
end
