require 'db_spec_helper'

module Stash
  module Merritt
    describe Repository do

      attr_reader :resource
      attr_reader :doi_value
      attr_reader :record_identifier
      attr_reader :repo

      before(:each) do
        user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )

        repo_config = OpenStruct.new(
          domain: 'merritt.cdlib.org',
          endpoint: 'http://uc3-mrtsword-prd.cdlib.org:39001/mrtsword/collection/dataone_dash'
        )

        tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:repository).and_return(repo_config)
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
        resource.current_state = 'processing'

        @doi_value = '10.15146/R3RG6G'
        expect(resource.identifier_value).to eq(doi_value) # just to be sure

        @record_identifier = 'http://n2t.net/ark:/99999/fk43f5119b'

        url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        @repo = Repository.new(url_helpers: url_helpers)
      end

      describe :download_uri_for do
        it 'determines the download URI' do
          expected_uri = 'http://merritt.cdlib.org/d/ark%3A%2F99999%2Ffk43f5119b'
          actual_uri = repo.download_uri_for(resource: resource, record_identifier: record_identifier)
          expect(actual_uri).to eq(expected_uri)
        end
      end

      describe :update_uri_for do
        it 'determines the update URI' do
          expected_uri = 'http://uc3-mrtsword-prd.cdlib.org:39001/mrtsword/edit/dataone_dash/doi%3A10.15146%2FR3RG6G'
          actual_uri = repo.update_uri_for(resource: resource, record_identifier: record_identifier)
          expect(actual_uri).to eq(expected_uri)
        end
      end

      describe :harvested do
        it 'sets the download URI, update URI, and status' do
          repo.harvested(resource: resource, record_identifier: record_identifier)
          expect(resource.download_uri).to eq('http://merritt.cdlib.org/d/ark%3A%2F99999%2Ffk43f5119b')
          expect(resource.update_uri).to eq('http://uc3-mrtsword-prd.cdlib.org:39001/mrtsword/edit/dataone_dash/doi%3A10.15146%2FR3RG6G')
          expect(resource.current_state).to eq('submitted')
        end
      end
    end
  end
end
