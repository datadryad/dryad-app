require 'db_spec_helper'
require 'pathname'

module Stash
  module Merritt
    describe ObjectManifestPackage do
      attr_reader :datacite_xml
      attr_reader :rails_root
      attr_reader :public_system
      attr_reader :resource
      attr_reader :root_url

      before(:each) do
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

        tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:full_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }
        allow(tenant).to receive(:sword_params).and_return(collection_uri: 'http://sword.example.edu/stash-dev')
        allow(tenant).to receive(:full_domain).and_return('stash.example.edu')
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date,
          tenant_id: 'dataone'
        ).build

        @root_url = 'https://stash.example.edu/'

        resource.new_file_uploads.find_each do |upload|
          upload_file_name = upload.upload_file_name
          filename_encoded = URI.encode_www_form_component(upload_file_name)
          filename_decoded = URI.decode_www_form_component(filename_encoded)
          expect(filename_decoded).to eq(upload_file_name) # just to be sure
          upload.url = "http://example.org/uploads/#{filename_encoded}"
          upload.status_code = 200
          upload.save
        end
      end

      after(:each) do
        FileUtils.remove_dir(rails_root)
      end

      describe :initialize do
        it 'sets the root URL' do
          package = ObjectManifestPackage.new(resource: resource)
          expect(package.root_url).to eq(URI("https://stash.example.edu/system/#{resource.id}/"))
        end

        it 'fails if the resource doesn\'t have an identifier' do
          resource.identifier = nil
          resource.save!
          expect { ObjectManifestPackage.new(resource: resource) }.to raise_error(ArgumentError)
        end

        it 'fails if the resource has no URL "uploads"'
        it 'fails if the resource has non-URL "uploads"'
      end

      describe :manifest do
        attr_reader :package
        attr_reader :manifest_path

        before(:each) do
          @package = ObjectManifestPackage.new(resource: resource)
          @manifest_path = package.create_manifest
        end

        it 'builds a manifest' do
          actual = File.read(manifest_path)

          # generated stash-wrapper.xml has today's date & so has different hash, file size
          generated_stash_wrapper = "#{public_system}/#{resource.id}/stash-wrapper.xml"
          stash_wrapper_md5 = Digest::MD5.file(generated_stash_wrapper).to_s
          stash_wrapper_size = File.size(generated_stash_wrapper)
          expected = File.read('spec/data/manifest.checkm')
            .sub(
              '17c28364d528eed4805d6b87afa88749 | 9838',
              "#{stash_wrapper_md5} | #{stash_wrapper_size}"
            ).gsub('{resource_id}', resource.id.to_s)

          expect(actual).to eq(expected)
        end

        describe 'public/system' do
          it 'writes mrt-dataone-manifest.txt' do
            actual = File.read("#{public_system}/#{resource.id}/mrt-dataone-manifest.txt")
            expected = File.read('spec/data/archive/mrt-dataone-manifest.txt')
            expect(actual).to eq(expected)
          end

          it 'writes stash-wrapper.xml' do
            actual = File.read("#{public_system}/#{resource.id}/stash-wrapper.xml")
            expected = File.read('spec/data/archive/stash-wrapper.xml')

            # ignore changed dates, trust that we've tested their accuracy elsewhere
            [actual, expected].each { |xml| xml.gsub!(/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]Z/, '') }

            expect(actual).to be_xml(expected)
          end

          it 'writes mrt-datacite.xml' do
            actual = File.read("#{public_system}/#{resource.id}/mrt-datacite.xml")
            expected = File.read('spec/data/archive/mrt-datacite.xml')
            expect(actual).to be_xml(expected)
          end

          it 'writes mrt-oaidc.xml' do
            actual = File.read("#{public_system}/#{resource.id}/mrt-oaidc.xml")
            expected = File.read('spec/data/archive/mrt-oaidc.xml')
            expect(actual).to be_xml(expected)
          end

          describe 'mrt-embargo.txt' do
            it 'sets end date to none if no end date present' do
              actual = File.read("#{public_system}/#{resource.id}/mrt-embargo.txt")
              expect(actual.strip).to eq('embargoEndDate:none')
            end

            it 'includes the embargo end date if present' do
              end_date = Time.new(2020, 1, 1, 0, 0, 1, '+12:45')
              resource.embargo = StashEngine::Embargo.new(end_date: end_date)
              @package = ObjectManifestPackage.new(resource: resource)
              @manifest_path = package.create_manifest
              actual = File.read("#{public_system}/#{resource.id}/mrt-embargo.txt")
              expect(actual.strip).to eq('embargoEndDate:2019-12-31T11:15:01Z')
            end
          end

          it 'writes mrt-delete.txt if needed' do
            deleted = []
            resource.file_uploads.each_with_index do |upload, index|
              next unless index.even?
              upload.file_state = 'deleted'
              upload.save
              deleted << upload.upload_file_name
            end

            @package = ObjectManifestPackage.new(resource: resource)
            @manifest_path = package.create_manifest

            manifest = File.read(manifest_path)
            expect(manifest).to include("https://stash.example.edu/system/#{resource.id}/mrt-delete.txt")
            mrt_delete = File.read("#{public_system}/#{resource.id}/mrt-delete.txt")
            deleted.each do |filename|
              expect(mrt_delete).to include(filename)
              expect(manifest).not_to include(filename)
            end
          end
        end
      end

      describe :dc4_xml do
        it 'builds Datacite 4 XML' do
          package = ObjectManifestPackage.new(resource: resource)
          expect(package.dc4_xml).to be_xml(datacite_xml)
        end
      end

      describe :to_s do
        attr_reader :package_str
        before(:each) do
          package = ObjectManifestPackage.new(resource: resource)
          @package_str = package.to_s
        end
        it 'includes the class name' do
          expect(package_str).to include(ObjectManifestPackage.name)
        end
        it 'includes the resource ID' do
          expect(package_str).to include(resource.id.to_s)
        end
      end

      describe SubmissionJob do
        describe :create_package do
          it 'returns a manifest package for a manifest resource' do
            logger = instance_double(Logger)
            allow(logger).to receive(:info)
            allow(Rails).to receive(:logger).and_return(logger)

            job = SubmissionJob.new(resource_id: resource.id, url_helpers: double(Module))
            package = job.send(:create_package)
            expect(package).to be_an(ObjectManifestPackage)
          end
        end
      end
    end
  end
end
