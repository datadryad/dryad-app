require 'fileutils'
require 'pathname'
require 'webmock'
require 'ostruct'

module Stash
  module Merritt
    describe MerrittHelper do
      include Mocks::Aws

      before(:all) do
        WebMock.disable_net_connect!(allow_localhost: true)

        @title = 'A Zebrafish Model for Studies on Esophageal Epithelial Biology'
        @request_host = 'example.org'

        @sword_params = {
          collection_uri: 'http://example.org/sword/my_collection',
          username: 'elvis',
          password: 'presley'
        }.freeze
      end

      before(:each) do
        mock_aws!

        @rails_root = Dir.mktmpdir('rails_root')
        FileUtils.mkdir_p("#{@rails_root}/tmp")
        allow(Rails).to receive(:root).and_return(@rails_root)

        public_path = Pathname.new("#{@rails_root}/public")
        allow(Rails).to receive(:public_path).and_return(public_path)
        allow(Rails).to receive(:application).and_return(OpenStruct.new(default_url_options: { host: 'stash.example.edu' }))

        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@example.edu',
                       tenant_id: 'dataone')
        @tenant = double(StashEngine::Tenant)
        allow(@tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                  id_scheme: 'doi')
        allow(@tenant).to receive(:tenant_id).and_return('dataone')
        allow(@tenant).to receive(:short_name).and_return('DataONE')
        allow(@tenant).to receive(:full_url) { |path| "https://stash-dev.example.edu/#{path}" }
        allow(@tenant).to receive(:sword_params).and_return(@sword_params)
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(@tenant)

        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(File.read('spec/data/archive/stash-wrapper.xml'))

        @doi = '10.15146/R3RG6G'
        @update_uri = "http://example.org/#{@doi}/edit"
        @download_uri = "http://example.org/#{@doi}/em"
        ident = create(:identifier, identifier: @doi)
        @resource = create(:resource,
                           user: @user,
                           tenant_id: 'dataone',
                           identifier: ident)
        create(:right, resource: @resource)
        # All tests assume this resource has not yet been submitted to Merritt, so remove the URIs
        @resource.download_uri = nil
        @resource.update_uri = nil

        stash_wrapper.inventory.files.each do |stash_file|
          data_file = stash_file.pathname
          placeholder_file = "#{@resource.upload_dir}/#{data_file}"
          parent = File.dirname(placeholder_file)
          FileUtils.mkdir_p(parent) unless File.directory?(parent)
          File.open(placeholder_file, 'w') do |f|
            f.puts("#{data_file}\t#{stash_file.size_bytes}\t#{stash_file.mime_type}\t(placeholder)")
          end
        end

        @receipt = instance_double(Stash::Sword::DepositReceipt)
        allow(@receipt).to(receive(:em_iri)).and_return(@download_uri)
        allow(@receipt).to(receive(:edit_iri)).and_return(@update_uri)

        @sword_client = instance_double(Stash::Sword::Client)
        allow(@sword_client).to receive(:update).and_return(200)
        allow(@sword_client).to receive(:create).and_return(@receipt)
        allow(Stash::Sword::Client).to receive(:new).and_return(@sword_client)
      end

      after(:each) do
        FileUtils.remove_entry_secure @rails_root
      end

      describe :submit! do
        describe "with #{Stash::Merritt::ObjectManifestPackage}" do

          before(:each) do
            @resource.new_data_files.find_each do |upload|
              upload_file_name = upload.upload_file_name
              filename_encoded = URI.encode_www_form_component(upload_file_name)
              filename_decoded = URI.decode_www_form_component(filename_encoded)
              expect(filename_decoded).to eq(upload_file_name) # just to be sure
              upload.url = "http://example.org/uploads/#{filename_encoded}"
              upload.save
            end
            allow(@resource).to receive(:upload_type).and_return(:manifest)
          end

          describe 'create' do

            before(:each) do
              @package = Stash::Merritt::ObjectManifestPackage.new(resource: @resource)
              @helper = SwordHelper.new(package: @package)
            end

            it 'submits the manifest' do
              expect(@sword_client).to receive(:create)
                .with(
                  doi: "doi:#{@doi}",
                  payload: @package.payload,
                  packaging: Stash::Sword::Packaging::BINARY
                ).and_return(@receipt)
              @helper.submit!
              expect(@resource.download_uri).to eq(@download_uri)
              expect(@resource.update_uri).to eq(@update_uri)
            end

            it 'sets the version "zipfile"' do
              @helper.submit!
              version = @resource.stash_version
              manifest = File.basename(@package.payload)
              expect(version.zip_filename).to eq(manifest)
            end

            it 'forwards errors' do
              expect(@sword_client).to receive(:create).and_raise(RestClient::RequestFailed)
              expect { @helper.submit! }.to raise_error(RestClient::RequestFailed)
            end

            it 'handles RestClient::Exceptions::ReadTimeout and returns and raises GoneAsynchronous exception' do
              expect(@sword_client).to receive(:create).and_raise(RestClient::Exceptions::ReadTimeout)
              expect { @helper.submit! }.to raise_error(Stash::Merritt::SwordHelper::GoneAsynchronous)
            end
          end

          describe 'update' do

            before(:each) do
              @resource.update_uri = @update_uri
              @resource.download_uri = @download_uri
              @resource.save
              @package = Stash::Merritt::ObjectManifestPackage.new(resource: @resource)
              @helper = SwordHelper.new(package: @package)
            end

            it 'submits the manifest' do
              expect(@sword_client).to receive(:update)
                .with(
                  edit_iri: @update_uri,
                  payload: @package.payload,
                  packaging: Stash::Sword::Packaging::BINARY
                ).and_return(200)
              @helper.submit!
            end

            it 'sets the version "zipfile"' do
              @helper.submit!
              version = @resource.stash_version
              manifest = File.basename(@package.payload)
              expect(version.zip_filename).to eq(manifest)
            end

            it 'forwards errors' do
              expect(@sword_client).to receive(:update).and_raise(RestClient::RequestFailed)
              expect { @helper.submit! }.to raise_error(RestClient::RequestFailed)
            end
          end
        end
      end
    end
  end
end
