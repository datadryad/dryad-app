require 'spec_helper'

module StashDatacite
  module Resource
    describe ResourceFileGeneration do
      attr_reader :user
      attr_reader :datacite_xml
      attr_reader :stash_wrapper_xml
      attr_reader :resource

      before(:each) do
        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-ucop@ucop.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          provider: 'developer',
          tenant_id: 'ucop'
        )

        @stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build
      end

      describe '#generate_merritt_zip' do
        it 'builds a zipfile' do
          true
        end
      end
    end
  end
end
