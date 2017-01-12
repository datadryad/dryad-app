require 'db_spec_helper'
require 'datacite/mapping/datacite_xml_factory'

module Datacite
  module Mapping
    describe DataciteXMLFactory do
      attr_reader :dc3_xml
      attr_reader :dcs_resource
      attr_reader :xml_factory

      before(:each) do
        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        doi_value = '10.15146/R3RG6G'
        total_size_bytes = 3_286_679

        @dc3_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(dc3_xml)

        user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )
        resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

        @xml_factory = DataciteXMLFactory.new(
          doi_value: doi_value,
          se_resource: resource,
          total_size_bytes: total_size_bytes,
          version: 1
        )
      end

      it 'generates DC3' do
        actual = xml_factory.build_datacite_xml(datacite_3: true)
        expect(actual).to be_xml(dc3_xml)
      end

      it 'generates DC4' do
        expected = File.read('spec/data/dc4-with-funding-references.xml')
        actual = xml_factory.build_datacite_xml
        expect(actual).to be_xml(expected)
      end
    end
  end
end
