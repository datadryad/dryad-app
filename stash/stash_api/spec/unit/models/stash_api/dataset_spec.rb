require 'db_spec_helper'
require_relative '../../../../../spec_helpers/factory_helper'
require 'byebug'

module StashApi
  RSpec.describe Dataset do
    before(:each) do

      # all these doubles are required because I can't get a url helper for creating URLs inside the tests.
      generic_path = double('generic_path')
      allow(generic_path).to receive(:dataset_path).and_return('dataset_foobar_path')
      allow(generic_path).to receive(:dataset_versions_path).and_return('dataset_versions_foobar_path')
      allow(generic_path).to receive(:version_path).and_return('version_foobar_path')
      allow(generic_path).to receive(:download_dataset_path).and_return('download_dataset_foobar_path')

      allow(Dataset).to receive(:api_url_helper).and_return(generic_path)

      @user = create(:user)
      @identifier = create(:identifier) do |identifier|
        identifier.resources.create do |r|
          r.user = @user
          r.current_editor_id = @user.id
          r.title = 'My Cats Have Fleas'
          r.tenant_id = @user.tenant_id
        end
      end

      create(:version) do |v|
        v.resource = @identifier.resources.first
      end

    end

    # this is just a basic test to be sure FactoryBot works.  It likes to break a lot.
    describe :factories do
      it 'creates a FactoryBot factory that works' do
        expect(@identifier).to be_valid
      end
    end

    describe :basic_dataset_view do

      before(:each) do
        @user.update(role: 'superuser') # need to be superuser to see all dataset info
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
      end

      it 'shows an appropriate string identifier under id' do
        expect(@metadata[:identifier]).to eq('doi:138/238/2238')
      end

      it 'shows correct title' do
        expect(@metadata[:title]).to eq('My Cats Have Fleas')
      end

      it 'shows a version number' do
        expect(@metadata[:versionNumber]).to eq(1)
      end

      it 'shows a correct version status' do
        expect(@metadata[:versionStatus]).to eq('in_progress')
      end

      it 'hides skipDataciteUpdate if false' do
        expect(@metadata[:skipDataciteUpdate]).to eq(nil)
      end

      it 'hides skipEmails if false' do
        expect(@metadata[:skipEmails]).to eq(nil)
      end

      it 'hides preserveCurationStatus if false' do
        expect(@metadata[:preserveCurationStatus]).to eq(nil)
      end

      it 'hides loosenValidation if false' do
        expect(@metadata[:loosenValidation]).to eq(nil)
      end

      it 'shows skipDataciteUpdate when true' do
        @identifier.in_progress_resource.update(skip_datacite_update: true)
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:skipDataciteUpdate]).to eq(true)
      end

      it 'shows skipEmails when true' do
        @identifier.in_progress_resource.update(skip_emails: true)
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:skipEmails]).to eq(true)
      end

      it 'shows preserveCurationStatus when true' do
        @identifier.in_progress_resource.update(preserve_curation_status: true)
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:preserveCurationStatus]).to eq(true)
      end

      it 'shows loosenValidation when true' do
        @identifier.in_progress_resource.update(loosen_validation: true)
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:loosenValidation]).to eq(true)
      end

      it 'has a curation status' do
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:curationStatus]).to eq('In Progress')
      end

      it 'has a sharing link when it is in peer_review status' do
        bogus_link = 'http://some.sharing.com/linkvalue'
        allow_any_instance_of(StashEngine::Share).to receive(:sharing_link).and_return(bogus_link)
        r = @identifier.resources.last
        StashEngine::CurationActivity.create(resource: r, status: 'peer_review')
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:sharingLink]).to be(bogus_link)
      end

    end

  end
end
