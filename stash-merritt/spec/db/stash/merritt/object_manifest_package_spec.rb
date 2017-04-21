require 'db_spec_helper'
require 'pathname'

module Stash
  module Merritt
    describe ObjectManifestPackage do
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
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )

        tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:landing_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }
        allow(tenant).to receive(:sword_params).and_return(collection_uri: 'http://sword.example.edu/stash-dev')
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

        @root_url = 'https://stash.example.edu/'

        resource.new_file_uploads.find_each do |upload|
          upload_file_name = upload.upload_file_name
          filename_encoded = ERB::Util.url_encode(upload_file_name)
          filename_decoded = URI.decode(filename_encoded)
          expect(filename_decoded).to eq(upload_file_name) # just to be sure

          url = "http://example.org/uploads/#{filename_encoded}"
          puts "Setting URL #{url}"

          upload.url = url
          upload.save
        end
      end

      after(:each) do
        FileUtils.remove_dir(rails_root)
      end

      describe :initialize do
        it 'sets the root URL' do
          package = ObjectManifestPackage.new(resource: resource, root_url: root_url)
          expect(package.root_url).to eq(URI('https://stash.example.edu/'))
        end

        it 'fails if root_url is nil' do
          expect { ObjectManifestPackage.new(resource: resource, root_url: nil) }.to raise_error(URI::InvalidURIError)
        end

        it 'fails if root_url is blank' do
          expect { ObjectManifestPackage.new(resource: resource, root_url: ' ') }.to raise_error(URI::InvalidURIError)
        end

        it 'fails if root_url is not a URL' do
          expect { ObjectManifestPackage.new(resource: resource, root_url: 'I am not a URL') }.to raise_error(URI::InvalidURIError)
        end

        it 'fails if the resource doesn\'t have an identifier' do
          resource.identifier = nil
          resource.save!
          expect { ObjectManifestPackage.new(resource: resource, root_url: root_url) }.to raise_error(ArgumentError)
        end

        it 'fails if the resource has no URL "uploads"'
        it 'fails if the resource has non-URL "uploads"'
      end

      describe :manifest do
        it 'builds a manifest' do
          package = ObjectManifestPackage.new(resource: resource, root_url: root_url)
          manifest_path = package.create_manifest
          fail "not implemented"
        end
        describe 'public/system' do
          it 'writes mrt-dataone-manifest.txt'
          it 'writes stash-wrapper.xml'
          it 'writes mrt-datacite.xml'
          it 'writes mrt-oaidc.xml'
          describe 'mrt-embargo.txt' do
            it 'includes the embargo end date if present'
            it 'sets end date to none if no end date present'
          end
          it 'writes mrt-delete.xml if needed'
        end
      end
    end
  end
end
