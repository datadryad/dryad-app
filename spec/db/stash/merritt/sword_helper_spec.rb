require 'db_spec_helper'

require 'fileutils'
require 'pathname'
require 'webmock'

module Stash
  module Merritt
    describe SwordHelper do
      attr_reader :title
      attr_reader :doi
      attr_reader :update_uri
      attr_reader :download_uri
      attr_reader :request_host
      attr_reader :request_port
      attr_reader :sword_params
      attr_reader :rails_root
      attr_reader :user
      attr_reader :tenant
      attr_reader :resource
      attr_reader :sword_client

      before(:all) do
        WebMock.disable_net_connect!

        @title = 'A Zebrafish Model for Studies on Esophageal Epithelial Biology'
        @doi = 'doi:10.15146/R3RG6G'
        @update_uri = "http://example.org/#{doi}/edit"
        @download_uri = "http://example.org/#{doi}/em"
        @request_host = 'example.org'
        @request_port = 80

        @sword_params = {
          collection_uri: 'http://example.org/sword/my_collection',
          username: 'elvis',
          password: 'presley'
        }.freeze
      end

      before(:each) do
        @rails_root = Dir.mktmpdir('rails_root')
        FileUtils.mkdir_p("#{rails_root}/tmp")
        allow(Rails).to receive(:root).and_return(rails_root)

        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )
        @tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                 id_scheme: 'doi')
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:landing_url) { |path| "https://stash-dev.example.edu/#{path}" }
        allow(tenant).to receive(:sword_params).and_return(sword_params)
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

        # TODO: move this to ResourceBuilder
        stash_wrapper.inventory.files.each do |stash_file|
          data_file = stash_file.pathname
          placeholder_file = "#{resource.upload_dir}/#{data_file}"
          parent = File.dirname(placeholder_file)
          FileUtils.mkdir_p(parent) unless File.directory?(parent)
          File.open(placeholder_file, 'w') do |f|
            f.puts("#{data_file}\t#{stash_file.size_bytes}\t#{stash_file.mime_type}\t(placeholder)")
          end
        end

        receipt = instance_double(Stash::Sword::DepositReceipt)
        allow(receipt).to(receive(:em_iri)).and_return(download_uri)
        allow(receipt).to(receive(:edit_iri)).and_return(update_uri)

        @sword_client = instance_double(Stash::Sword::Client)
        allow(sword_client).to receive(:update).and_return(200)
        allow(sword_client).to receive(:create) { receipt }
        allow(Stash::Sword::Client).to receive(:new).and_return(sword_client)
      end

      after(:each) do
        FileUtils.remove_entry_secure rails_root
      end

      describe :submit! do
        describe 'create' do
          it 'submits the zipfile' do
            package = Stash::Merritt::SubmissionPackage.new(resource: resource)
            helper = SwordHelper.new(package: package)
            expect(sword_client).to receive(:create).with(doi: doi, zipfile: package.zipfile)
            helper.submit!
          end

          it 'sets the update and download URIs'
          it 'sets the version zipfile'
          it 'forwards errors'
        end

        describe 'update' do
          before(:each) do
            resource.update_uri = update_uri
            resource.download_uri = download_uri
            resource.save
          end

          it 'submits the zipfile' do
            package = Stash::Merritt::SubmissionPackage.new(resource: resource)
            helper = SwordHelper.new(package: package)
            expect(sword_client).to receive(:update).with(edit_iri: update_uri, zipfile: package.zipfile).and_return(200)
            helper.submit!
          end

          it 'sets the version zipfile'
          it 'forwards errors'
        end
      end
    end
  end
end
