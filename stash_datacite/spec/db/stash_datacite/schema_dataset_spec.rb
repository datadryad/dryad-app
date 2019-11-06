require 'db_spec_helper'
require 'json'

module StashDatacite
  module Resource
    describe SchemaDataset do
      attr_reader :user
      attr_reader :stash_wrapper
      attr_reader :dcs_resource

      attr_reader :resource
      attr_reader :schema_dataset

      before(:all) do
        @user = StashEngine::User.create(
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )

        dc3_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(dc3_xml)
        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        @stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)
      end

      before(:each) do
        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build
        resource.download_uri = "https://repo.example.edu/#{resource.identifier_str}.zip"
        resource.save

        landing_page_url = "https://stash-dev.example.edu/#{resource.identifier_str}"
        citation = 'Chen, Hao (2016), A Zebrafish Model for Studies on Esophageal Epithelial Biology, Dataset, https://doi.org/10.15146/R3RG6G'
        @schema_dataset = SchemaDataset.new(resource: resource, citation: citation, landing: landing_page_url)
      end

      it 'generates schema.org JSON' do
        expected = JSON.parse(File.read('spec/data/example.json'))
        json_hash = schema_dataset.generate
        actual = JSON.parse(json_hash.to_json)
        expect(actual).to eq(expected)
      end
    end
  end
end
