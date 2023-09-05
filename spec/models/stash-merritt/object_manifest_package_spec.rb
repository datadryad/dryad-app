require 'pathname'
require 'ostruct'

module Stash
  module Merritt
    describe ObjectManifestPackage do
      include Mocks::Aws

      before(:each) do
        mock_aws!

        @rails_root = Dir.mktmpdir('rails_root')
        root_path = Pathname.new(@rails_root)
        allow(Rails).to receive(:root).and_return(root_path)
        public_path = Pathname.new("#{@rails_root}/public")
        allow(Rails).to receive(:public_path).and_return(public_path)
        allow(Rails).to receive(:application).and_return(OpenStruct.new(default_url_options: { host: 'stash.example.edu' }))

        @public_system = public_path.join('system').to_s
        FileUtils.mkdir_p(@public_system)

        user = create(:user,
                      first_name: 'Lisa',
                      last_name: 'Muckenhaupt',
                      email: 'lmuckenhaupt@example.edu',
                      tenant_id: 'dataone')

        tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:full_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }
        allow(tenant).to receive(:sword_params).and_return(collection_uri: 'http://sword.example.edu/stash-dev')
        allow(tenant).to receive(:identifier_service).and_return(
          { provider: 'ezid', shoulder: 'doi:10.5072/FK2', account: 'brog', password: 'new', id_scheme: 'doi', owner: nil }.to_ostruct
        )

        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

        @root_url = 'https://stash.example.edu/'

        @resource = create(:resource, user: user)
        @resource.save
        create(:right, resource: @resource)
        create(:resource_type, resource: @resource)
        create(:author, resource: @resource)
        create(:author, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        @resource.reload

        @resource.new_data_files.find_each do |upload|
          upload_file_name = upload.upload_file_name
          filename_encoded = URI.encode_www_form_component(upload_file_name)
          filename_decoded = URI.decode_www_form_component(filename_encoded)
          expect(filename_decoded).to eq(upload_file_name) # just to be sure
          upload.url = "http://example.org/uploads/#{filename_encoded}"
          upload.status_code = 200
          upload.save
        end
        FileUtils.mkdir_p("#{@public_system}/#{@resource.id}")

      end

      after(:each) do
        FileUtils.remove_dir(@rails_root)
      end

      describe :initialize do
        it 'sets the root URL' do
          package = ObjectManifestPackage.new(resource: @resource)
          expect(package.root_url).to eq(URI("https://stash.example.edu/system/#{@resource.id}/"))
        end
      end

      describe :manifest do
        let(:instance) { instance_double(Stash::Aws::S3) }
        let(:double_class) {
          class_double(Stash::Aws::S3).as_stubbed_const
        }

        before(:each) do
          # make Stash::Aws::S3 an rspec "spy", so we can test how it was called
          allow(Stash::Aws::S3).to receive(:new).and_return(instance)
          allow(instance).to receive(:put)
          allow(instance).to receive(:presigned_download_url).and_return('http://example.org/')
          package = ObjectManifestPackage.new(resource: @resource)
          package.create_manifest
        end

        it 'builds a manifest' do
          # expect(instance).to have_received(:put)
          expect(instance).to have_received(:put).with(s3_key: /manifest\.checkm/,
                                                             contents: /%checkm_/).at_least(:once)
          expect(instance).to have_received(:put).with(s3_key: /manifest\.checkm/,
                                                             contents: %r{stash-wrapper\.xml \| text/xml}).at_least(:once)
        end

        describe 'public/system' do
          it 'writes mrt-dataone-manifest.txt' do
            # This file should look like spec/data/stash-merritt/mrt-dataone-manifest.txt
            package = ObjectManifestPackage.new(resource: @resource)
            the_path = package.create_manifest
            @resource.new_data_files.find_each do |upload|
              target_string = "#{upload.upload_file_name} | #{upload.upload_content_type}"
              expect(instance).to have_received(:put)
                .with(s3_key: /mrt-dataone-manifest\.txt/,
                      contents: /#{Regexp.quote(target_string)}/)
                .at_least(:once)
            end
          end

          it 'writes stash-wrapper.xml' do
            # This file should look like spec/data/stash-merritt/stash-wrapper.xml
            target_string = "<st:identifier type='DOI'>#{@resource.identifier.identifier}</st:identifier>"
            expect(instance).to have_received(:put)
              .with(s3_key: /stash-wrapper\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = "<publicationYear>#{@resource.publication_date.year}</publicationYear>"
            expect(instance).to have_received(:put)
              .with(s3_key: /stash-wrapper\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = "<title>#{@resource.title}</title>"
            expect(instance).to have_received(:put)
              .with(s3_key: /stash-wrapper\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
          end

          it 'writes mrt-datacite.xml' do
            # This file should look like spec/data/stash-merritt/mrt-datacite.xml
            target_string = "<title>#{@resource.title}</title>"
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-datacite\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = "<publicationYear>#{@resource.publication_date.year}</publicationYear>"
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-datacite\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = "<identifier identifierType='DOI'>#{@resource.identifier.identifier}</identifier>"
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-datacite\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
          end

          it 'writes mrt-oaidc.xml' do
            # This file should look like spec/data/stash-merritt/mrt-oaidc.xml
            target_string = "<dc:creator>#{@resource.authors.first.author_full_name}</dc:creator>"
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-oaidc\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = "<dc:title>#{@resource.title}</dc:title>"
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-oaidc\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
            target_string = '<dc:publisher>DataONE</dc:publisher>'
            expect(instance).to have_received(:put)
              .with(s3_key: /mrt-oaidc\.xml/,
                    contents: /#{Regexp.quote(target_string)}/)
              .at_least(:once)
          end

          it 'writes mrt-delete.txt if needed' do
            deleted = []
            @resource.data_files.each_with_index do |upload, index|
              next unless index.even?

              upload.file_state = 'deleted'
              upload.save
              deleted << upload.upload_file_name
            end

            # allow_any_instance_of(Stash::Aws::S3).to receive(:put)
            package = ObjectManifestPackage.new(resource: @resource)
            package.create_manifest

            expect(instance).to have_received(:put).with(s3_key: /manifest\.checkm/,
                                                                               contents: /mrt-delete\.txt/).at_least(:once)
            deleted.each do |filename|
              expect(instance).to have_received(:put)
                .with(s3_key: /mrt-delete\.txt/,
                      contents: /#{Regexp.quote(filename)}/)
                .at_least(:once)
            end
          end
        end
      end

      describe :dc4_xml do
        it 'builds Datacite 4 XML' do
          # Should be like spec/data/stash-merritt/mrt-datacite.xml
          package = ObjectManifestPackage.new(resource: @resource)
          actual = Hash.from_xml(package.dc4_xml)
          actual_res = actual['resource']
          expect(actual_res['titles']['title']).to eq(@resource.title)
          expect(actual_res['identifier']).to eq(@resource.identifier.identifier)
          expect(actual_res['publicationYear']).to eq(@resource.publication_date.year.to_s)
        end
      end

      describe :to_s do
        attr_reader :package_str
        before(:each) do
          package = ObjectManifestPackage.new(resource: @resource)
          @package_str = package.to_s
        end
        it 'includes the class name' do
          expect(package_str).to include(ObjectManifestPackage.name)
        end
        it 'includes the resource ID' do
          expect(package_str).to include(@resource.id.to_s)
        end
      end

      describe SubmissionJob do
        describe :create_package do
          it 'returns a manifest package for a manifest resource' do
            logger = instance_double(Logger)
            allow(logger).to receive(:info)
            allow(Rails).to receive(:logger).and_return(logger)

            job = SubmissionJob.new(resource_id: @resource.id, url_helpers: double(Module))
            allow(job).to receive(:id_helper).and_return(OpenStruct.new(ensure_identifier: 'meow'))
            package = job.send(:create_package)
            expect(package).to be_an(ObjectManifestPackage)
          end
        end
      end
    end
  end
end
