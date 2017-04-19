require 'db_spec_helper'
require 'pathname'

module Stash
  module Merritt
    describe ObjectManifestPackage do
      attr_reader :rails_root
      attr_reader :public_system

      before(:each) do
        @rails_root = Dir.mktmpdir('rails_root')
        root_path = Pathname.new(rails_root)
        allow(Rails).to receive(:root).and_return(root_path)

        public_path = Pathname.new("#{rails_root}/public")
        allow(Rails).to receive(:public_path).and_return(public_path)

        @public_system = public_path.join('system').to_s
        FileUtils.mkdir_p(public_system)

        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )
        @tenant = double(StashEngine::Tenant)

        @stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

      end

      after(:each) do
        FileUtils.remove_dir(rails_root)
      end

      describe :initialize do
        it 'fails if the resource doesn\'t have an identifier'
        it 'fails if the resource has no URL "uploads"'
        it 'fails if the resource has non-URL "uploads"'
      end

      describe :manifest do
        it 'builds a manifest'
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
