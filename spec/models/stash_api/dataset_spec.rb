require 'byebug'

module StashApi
  RSpec.describe Dataset do
    include Mocks::Tenant
    include Mocks::Datacite
    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      mock_tenant!
      # all these doubles are required because I can't get a url helper for creating URLs inside the tests.
      generic_path = double('generic_path')
      allow(generic_path).to receive(:dataset_path).and_return('dataset_foobar_path')
      allow(generic_path).to receive(:dataset_versions_path).and_return('dataset_versions_foobar_path')
      allow(generic_path).to receive(:version_path).and_return('version_foobar_path')
      allow(generic_path).to receive(:download_dataset_path).and_return('download_dataset_foobar_path')

      allow(Dataset).to receive(:api_url_helper).and_return(generic_path)

      @user = create(:user)
      @identifier = create(:identifier)
      @resource = create(:resource, identifier: @identifier, user: @user,
                                    current_editor_id: @user.id, title: 'My Cats Have Fleas')

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
        expect(@metadata[:identifier]).to start_with('doi:10.')
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
        expect(@metadata[:curationStatus]).to eq('In progress')
      end

      it 'has an edit link' do
        expect(@metadata[:editLink]).to include('/edit/')
      end

      it 'does not have an edit link when the request is made by a non-privileged user' do
        @dataset = Dataset.new(identifier: @identifier.to_s, user: create(:user))
        @metadata = @dataset.metadata
        expect(@metadata[:editLink]).to eq(nil)
      end

      it 'has a lastModificationDate' do
        expect(@metadata[:lastModificationDate]).to eq(Time.now.utc.strftime('%Y-%m-%d'))
      end

      it 'has relatedWorks' do
        ri = create(:related_identifier, :publication_doi, resource: @resource)
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        rw = @metadata[:relatedWorks].first
        expect(rw[:identifier]).to eq(ri.related_identifier)
        expect(rw[:identifierType]).to eq('DOI')
        expect(rw[:relationship]).to eq('article')
      end

      it 'defaults to the correct license' do
        expect(@metadata[:license]).to eq('https://creativecommons.org/publicdomain/zero/1.0/')
      end

      it 'has public visibility when metadata is viewable' do
        @resource.meta_view = true
        @resource.save
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:visibility]).to eq('public')
      end

      it 'has public visibility when files are viewable' do
        @resource.file_view = true
        @resource.save
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:visibility]).to eq('public')
      end

      it 'has restricted visibility when nothing is viewable' do
        expect(@metadata[:visibility]).to eq('restricted')
      end

      it 'has a sharingLink when it is in peer_review status' do
        bogus_link = 'http://some.sharing.com/linkvalue'
        allow_any_instance_of(StashEngine::Share).to receive(:sharing_link).and_return(bogus_link)
        r = @identifier.resources.last
        create(:curation_activity, resource: r, status: 'peer_review')
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:sharingLink]).to be(bogus_link)
      end

      it 'has no sharingLink when it is in embargoed or withdrawn status' do
        bogus_link = 'http://some.sharing.com/linkvalue'
        allow_any_instance_of(StashEngine::Share).to receive(:sharing_link).and_return(bogus_link)
        r = @identifier.resources.last

        StashEngine::CurationActivity.create(resource: r, status: 'embargoed')
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:sharingLink]).to be(nil)

        StashEngine::CurationActivity.create(resource: r, status: 'withdrawn')
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:sharingLink]).to be(nil)
      end

      it 'has a sharingLink when the current version is in_progress, but the previous version is still peer_review' do
        mock_datacite_gen!
        bogus_link = 'http://some.sharing.com/linkvalue'
        allow_any_instance_of(StashEngine::Share).to receive(:sharing_link).and_return(bogus_link)
        r = @identifier.resources.last
        StashEngine::CurationActivity.create(resource: r, status: 'peer_review')
        r.current_resource_state.update(resource_state: 'submitted')
        r2 = create(:resource, identifier: @identifier, user: @user,
                               current_editor_id: @user.id, title: 'The other resource')
        StashEngine::CurationActivity.create(resource: r2, status: 'in_progress')
        @dataset = Dataset.new(identifier: @identifier.to_s, user: @user)
        @metadata = @dataset.metadata
        expect(@metadata[:sharingLink]).to be(bogus_link)
      end

    end
  end
end
