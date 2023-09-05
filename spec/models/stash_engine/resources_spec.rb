module StashEngine

  describe Resource, type: :model do
    include Mocks::Salesforce

    attr_reader :user
    attr_reader :skip_emails
    attr_reader :future_date

    before(:each) do
      mock_salesforce!
      tomorrow = Date.today + 1
      @future_date = tomorrow + 366.days
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'ucop'
      )
      allow_any_instance_of(CurationActivity).to receive(:update_solr).and_return(true)
      allow_any_instance_of(CurationActivity).to receive(:process_payment).and_return(true)
      allow_any_instance_of(CurationActivity).to receive(:submit_to_datacite).and_return(true)

      # Mock all the mailers fired by callbacks because these tests don't load everything we need
      allow_any_instance_of(CurationActivity).to receive(:email_status_change_notices).and_return(true)
      allow_any_instance_of(CurationActivity).to receive(:email_orcid_invitations).and_return(true)

      allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
    end

    context 'cleanup_blank_models!' do
      before(:each) do
        @identifier = create(:identifier)
        @resource = Resource.create(user_id: @user.id, identifier: @identifier)
      end

      it 'removes unwanted related identifiers that have no identifier' do
        create(:related_identifier, resource: @resource, related_identifier: '')
        create(:related_identifier, resource: @resource)
        expect(@resource.related_identifiers.count).to eq(2)
        @resource.cleanup_blank_models!
        @resource.reload
        expect(@resource.related_identifiers.count).to eq(1)
      end

    end

    context 'peer_review' do

      describe :requires_peer_review? do
        let!(:resource) { create(:resource, identifier: create(:identifier)) }

        it 'returns false if hold_for_peer_review flag is not set' do
          expect(resource.send(:hold_for_peer_review?)).to eql(false)
        end
        it 'returns true if hold_for_peer_review flag is set' do
          resource.hold_for_peer_review = true
          expect(resource.send(:hold_for_peer_review?)).to eql(true)
        end
        it 'returns false if hold_for_peer_review flag is not set and there is no publication defined' do
          expect(resource.send(:hold_for_peer_review?)).to eql(false)
        end
      end

      describe :send_software_to_zenodo do
        before(:each) do
          @resource = create(:resource, identifier: create(:identifier))
          @identifier = @resource.identifier
          @resource.software_files << create(:software_file)
        end

        it 'sends the software to zenodo' do
          expect(@identifier).to receive(:has_zenodo_software?).and_call_original
          expect(StashEngine::ZenodoSoftwareJob).to receive(:perform_later)
          @resource.send_software_to_zenodo
          copy_record = @resource.zenodo_copies.software.first
          expect(copy_record.resource_id).to eq(@resource.id)
          expect(copy_record.state).to eq('enqueued')
        end
      end
    end

    describe :send_supp_to_zenodo do
      before(:each) do
        @resource = create(:resource, identifier: create(:identifier))
        @identifier = @resource.identifier
        @resource.supp_files << create(:supp_file)
      end

      it 'sends the supplemental to zenodo' do
        expect(@identifier).to receive(:has_zenodo_supp?).and_call_original
        expect(StashEngine::ZenodoSuppJob).to receive(:perform_later)
        @resource.send_supp_to_zenodo
        copy_record = @resource.zenodo_copies.supp.first
        expect(copy_record.resource_id).to eq(@resource.id)
        expect(copy_record.state).to eq('enqueued')
      end
    end

    describe :s3_dir_name do

      before(:each) do
        @resource = create(:resource, identifier: create(:identifier))
        @identifier = @resource.identifier
      end

      it 'sets a correct directory name for non-stage/prod s3' do
        dir_name = @resource.s3_dir_name
        expect(/[0-9a-fA-F]{8}-#{@resource.id}/).to match(dir_name)
      end

      it 'appends sfw for software' do
        dir_name = @resource.s3_dir_name(type: 'software')
        expect(%r{[0-9a-fA-F]{8}-#{@resource.id}/sfw}).to match(dir_name)
      end

      it 'appends supp for supplemental information' do
        dir_name = @resource.s3_dir_name(type: 'supplemental')
        expect(%r{[0-9a-fA-F]{8}-#{@resource.id}/supp}).to match(dir_name)
      end

      it "doesn't have a machine name hash for production environment" do
        allow(Rails).to receive('env').and_return('production')
        dir_name = @resource.s3_dir_name
        expect(dir_name).to eql("#{@resource.id}/data")
      end

      it 'also has suffixes such as _sfw on production' do
        allow(Rails).to receive('env').and_return('production')
        dir_name = @resource.s3_dir_name(type: 'software')
        expect("#{@resource.id}/sfw").to eql(dir_name)
      end

      it 'gets the correct name when called multiple times' do
        @resource.s3_dir_name(type: 'software')
        dir_name = @resource.s3_dir_name(type: 'data')
        expect(%r{[0-9a-fA-F]{8}-#{@resource.id}/data}).to match(dir_name)
      end

      it 'removes the S3 temporary files when the resource is destroyed' do
        expect_any_instance_of(Stash::Aws::S3).to receive(:delete_dir)
        @resource.s3_dir_name(type: 'base')
        @resource.destroy
      end
    end

    describe :title do
      it 'gets the correct clean_title' do
        test_title = 'some test title'
        resource = create(:resource, title: test_title)
        expect(resource.clean_title).to eq(test_title)

        resource = create(:resource, title: "Data from: #{test_title}")
        expect(resource.clean_title).to eq(test_title)
      end
    end

    describe :tenant do
      it 'returns the resource tenant' do
        tenant = instance_double(Tenant)
        allow(Tenant).to receive(:find).with('ucop').and_return(tenant)

        resource = Resource.create(tenant_id: 'ucop')
        expect(resource.tenant).to eq(tenant)
      end
    end

    describe :can_edit do
      it 'returns false if editing by someone else' do
        identifier = create(:identifier, identifier: 'cat/dog', identifier_type: 'DOI')
        editor = create(:user, first_name: 'L',
                               last_name: 'Mu',
                               email: 'lm@ucop.edu',
                               tenant_id: 'ucop',
                               role: 'user')
        resource = create(:resource, user_id: @user.id, identifier_id: identifier.id,
                                     current_editor_id: editor.id, tenant_id: 'ucop')
        ResourceState.create(user_id: editor.id, resource_state: 'in_progress', resource_id: resource.id)

        expect(resource.can_edit?(user: @user)).to eq(false)
      end
    end

    describe :permission_to_edit do
      it 'returns false if not owner' do
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucb')
        expect(resource.permission_to_edit?(user: @user)).to eq(false)
      end

      it 'returns true if superuser' do
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucb')
        @user.role = 'superuser'
        expect(resource.permission_to_edit?(user: @user)).to eq(true)
      end

      it 'returns true if curator' do
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucb')
        @user.role = 'curator'
        expect(resource.permission_to_edit?(user: @user)).to eq(true)
      end

      it 'returns false if admin for different tenant' do
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucb')
        @user.role = 'admin'
        expect(resource.permission_to_edit?(user: @user)).to eq(false)
      end

      it 'returns true if admin for same tenant' do
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucop')
        @user.role = 'admin'
        expect(resource.permission_to_edit?(user: @user)).to eq(true)
      end

      it 'returns true if admin for same journal' do
        journal = Journal.create(title: 'Test Journal', issn: '1234-4321')
        identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        InternalDatum.create(identifier_id: identifier.id, data_type: 'publicationISSN', value: journal.single_issn)
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucop', identifier_id: identifier.id)
        JournalRole.create(journal: journal, user: @user, role: 'admin')

        expect(resource.permission_to_edit?(user: @user)).to eq(true)
      end

      it 'returns true if admin for a journal, and the item has no journal set' do
        journal = Journal.create(title: 'Test Journal', issn: '1234-4321')
        identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucop', identifier_id: identifier.id)
        JournalRole.create(journal: journal, user: @user, role: 'admin')

        expect(resource.permission_to_edit?(user: @user)).to eq(true)
      end

    end

    describe :tenant_id do
      it 'returns the user tenant ID' do
        resource = Resource.create(tenant_id: 'ucop')
        expect(resource.tenant_id).to eq('ucop')
      end
    end

    describe 'Merrit-specific URL shenanigans' do
      describe :merritt_producer_download_uri do
        it 'returns the producer download URI' do
          download_uri = 'https://merritt.example.edu/d/ark%3A%2Fb5072%2Ffk2736st5z'
          resource = create(:resource, user_id: user.id)
          resource.download_uri = download_uri
          expect(resource.merritt_producer_download_uri).to eq('https://merritt.example.edu/u/ark%3A%2Fb5072%2Ffk2736st5z/1')
        end
      end

      # TODO: this shouldn't be in StashEngine
      describe :merritt_protodomain_and_local_id do
        it 'returns the merritt protocol and domain and local ID' do
          download_uri = 'https://merritt.example.edu/d/ark%3A%2Fb5072%2Ffk2736st5z'
          resource = Resource.create(user_id: user.id)
          resource.download_uri = download_uri

          merritt_protodomain, local_id = resource.merritt_protodomain_and_local_id
          expect(merritt_protodomain).to eq('https://merritt.example.edu')
          expect(local_id).to eq('ark%3A%2Fb5072%2Ffk2736st5z')
        end
      end
    end

    describe :publication_date do
      it 'defaults to nil' do
        resource = Resource.create(user_id: user.id)
        expect(resource.publication_date).to be_nil
      end

      it 'is copied by amoeba duplication' do
        pub_date = Time.new(2015, 5, 18, 13, 25, 30)
        r1 = Resource.create(user_id: user.id, publication_date: pub_date)
        r2 = r1.amoeba_dup
        expect(r2.publication_date).to eq(pub_date)
      end
    end

    describe :dataset_in_progress_editor_id do
      it 'defaults to current_editor for no identifier' do
        resource = Resource.create(user_id: user.id, current_editor_id: 1)
        expect(resource.dataset_in_progress_editor_id).to eq(1)
      end

      it 'gives editor id of in progress version' do
        identifier = create(:identifier, identifier: 'cat/dog', identifier_type: 'DOI')
        editor1 = create(:user)
        editor2 = create(:user)
        resource1 = create(:resource, user_id: user.id, identifier_id: identifier.id, current_editor_id: editor1.id)
        resource2 = create(:resource, user_id: user.id, identifier_id: identifier.id, current_editor_id: editor2.id)
        state1 = ResourceState.create(user_id: editor1.id, resource_state: 'submitted', resource_id: resource1.id)
        state2 = ResourceState.create(user_id: editor2.id, resource_state: 'in_progress', resource_id: resource2.id)
        resource1.update(current_resource_state_id: state1.id)
        resource2.update(current_resource_state_id: state2.id)

        # gives the in progress dataset's editor_id even though this one isn't in progress
        expect(resource1.dataset_in_progress_editor_id).to eq(editor2.id)
        expect(resource2.dataset_in_progress_editor_id).to eq(editor2.id)
        resource2.delete
        expect(resource1.dataset_in_progress_editor_id).to eq(nil) # no in-progress should return a nil
      end

      it 'gives editor of in progress version' do
        user1 = create(:user)
        user2 = create(:user)
        identifier = create(:identifier, identifier: 'cat/dog', identifier_type: 'DOI')
        resource1 = create(:resource, user_id: user1.id, identifier_id: identifier.id, current_editor_id: user1.id)
        resource2 = create(:resource, user_id: user1.id, identifier_id: identifier.id, current_editor_id: user2.id)
        state1 = ResourceState.create(user_id: user1.id, resource_state: 'submitted', resource_id: resource1.id)
        state2 = ResourceState.create(user_id: user2.id, resource_state: 'in_progress', resource_id: resource2.id)
        resource1.update(current_resource_state_id: state1.id)
        resource2.update(current_resource_state_id: state2.id)
        expect(resource1.dataset_in_progress_editor.id).to eq(user2.id)
        expect(resource2.dataset_in_progress_editor.id).to eq(user2.id)
        resource2.delete
        expect(resource1.dataset_in_progress_editor.id).to eq(user1.id)
      end
    end

    describe 'solr fun' do
      before(:each) do
        blacklight_hash = { solr_url: 'http://test.com/blah/geoblacklight' }
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        @resource = Resource.create(user_id: user.id, identifier_id: @identifier.id)

        @my_indexer = instance_double('SolrIndexer')
        allow(@my_indexer).to receive(:index_document).and_return(true)
        allow(Stash::Indexer::SolrIndexer).to receive(:new).and_return(@my_indexer)

        @my_indexing_resource = instance_double('IndexingResource')
        allow(@my_indexing_resource).to receive(:to_index_document).and_return({})
        allow(Stash::Indexer::IndexingResource).to receive(:new).and_return(@my_indexing_resource)

        object_double('Blacklight').as_stubbed_const
        allow(Blacklight).to receive(:connection_config).and_return(blacklight_hash)
      end

      describe '#submit_to_solr' do
        it 'saves true for solr_indexed if submission worked' do
          @resource.submit_to_solr
          expect(@resource.solr_indexed).to be(true)
        end

        it 'leaves false for solr_indexed if submission failed' do
          allow(@my_indexer).to receive(:index_document).and_return(false)
          @resource.submit_to_solr
          expect(@resource.solr_indexed).to be(false)
        end
      end

      describe '#delete_from_solr' do

        before(:each) do
          allow(Stash::Indexer::SolrIndexer).to receive(:new).and_return(@my_indexer)
          @resource.update(solr_indexed: true)
        end

        it 'saves false for solr_indexed if deletion worked' do
          allow(@my_indexer).to receive(:delete_document).and_return(true)
          @resource.delete_from_solr
          expect(@resource.solr_indexed).to be(false)
        end

        it 'leaves true if for solr_indexed if delete failed' do
          allow(@my_indexer).to receive(:delete_document).and_return(false)
          @resource.delete_from_solr
          expect(@resource.solr_indexed).to be(true)
        end
      end
    end

    describe :may_download? do
      before(:each) do
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI', pub_state: 'published')
        @resource = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: true, file_view: true)
        @merritt_state = ResourceState.create(user_id: @resource.user.id, resource_state: 'submitted', resource_id: @resource.id)
        @resource.update(current_resource_state_id: @merritt_state.id)
      end

      # Checks if someone may download files for this resource

      it 'returns false if not marked for download' do
        @resource.update(file_view: false)
        expect(@resource.may_download?(ui_user: nil)).to be false
      end

      it 'returns false if not successfully in Merritt' do
        @merritt_state.update(resource_state: 'in_progress')
        @resource.curation_activities << CurationActivity.new(status: 'published')
        @resource.reload
        user2 = User.create(tenant_id: 'ucop', first_name: 'Gopher', last_name: 'Jones', role: 'superuser')
        expect(@resource.may_download?(ui_user: user2)).to be false
      end

      it 'returns true if published' do
        # already set to published in identifier and this file_view is true
        expect(@resource.may_download?(ui_user: nil)).to be true
      end

      it 'returns false if embargoed' do
        @resource.identifier.update(pub_state: 'embargoed')
        @resource.update(file_view: false)
        @resource.reload
        expect(@resource.may_download?(ui_user: nil)).to be false
      end

      it 'returns false if not published' do
        @resource.identifier.update(pub_state: 'unpublished')
        @resource.update(file_view: false)
        @resource.reload
        expect(@resource.may_download?(ui_user: nil)).to be false
      end

      it 'returns true if unpublished, but if viewing user is the owner' do
        @resource.identifier.update(pub_state: 'unpublished')
        @resource.update(file_view: false)
        @resource.reload
        expect(@resource.may_download?(ui_user: @resource.user)).to be true
      end

      it 'returns true if being viewed by a curator' do
        @resource.identifier.update(pub_state: 'unpublished')
        @resource.update(file_view: false)
        @resource.reload
        a_curator = User.create(role: 'curator')
        expect(@resource.may_download?(ui_user: a_curator)).to be true
      end

      it 'returns true if being viewed by a journal admin' do
        journal = Journal.create(title: 'Test Journal', issn: '1234-4321')
        identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        identifier.update(pub_state: 'unpublished')
        InternalDatum.create(identifier_id: identifier.id, data_type: 'publicationISSN', value: journal.single_issn)
        resource = Resource.create(user_id: @user.id + 1, tenant_id: 'ucop', identifier_id: identifier.id)
        resource.update(file_view: false)
        JournalRole.create(journal: journal, user: @user, role: 'admin')

        expect(@resource.may_download?(ui_user: @user)).to be true
      end

    end

    # able to view based on curation state
    describe '#may_view?' do
      before(:each) do
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI', pub_state: 'embargoed')
        @resource = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: true, file_view: true)
        @merritt_state = ResourceState.create(user_id: @resource.user.id, resource_state: 'submitted', resource_id: @resource.id)
        @resource.update(current_resource_state_id: @merritt_state.id)
      end

      it 'allows anyone to view public resource' do
        expect(@resource.may_view?(ui_user: nil)).to be_truthy
      end

      it 'disallows unknown users from viewing private resource' do
        @resource.update(meta_view: false, file_view: false)
        @resource.reload
        expect(@resource.may_view?(ui_user: nil)).to be_falsey
      end

      it 'allows owner to view private resource' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(meta_view: false, file_view: false)
        @resource.reload
        expect(@resource.may_view?(ui_user: user)).to be_truthy
      end

      it 'disallows other normal user from viewing private' do
        @user2 = StashEngine::User.create(first_name: 'Gorgonzola', last_name: 'Travesty', tenant_id: 'ucop', role: 'user')
        @resource.update(meta_view: false, file_view: false)
        @resource.reload
        expect(@resource.may_view?(ui_user: @user2)).to be_falsey
      end

      it 'allows admin user from same tenant to view' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(tenant_id: user.tenant_id)
        @user2 = StashEngine::User.create(first_name: 'Gorgonzola', last_name: 'Travesty', tenant_id: user.tenant_id, role: 'admin')
        @resource.update(meta_view: false, file_view: false)
        @resource.reload
        expect(@resource.may_view?(ui_user: @user2)).to be_truthy
      end

      it 'denies admin user from other tenant to view' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(tenant_id: 'superca', meta_view: false, file_view: false)
        @user2 = StashEngine::User.create(first_name: 'Gorgonzola', last_name: 'Travesty', tenant_id: user.tenant_id, role: 'admin')
        expect(@resource.may_view?(ui_user: @user2)).to be_falsey
      end

      it 'allows admin user from journal to view' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(tenant_id: 'superca', meta_view: false, file_view: false)
        @user2 = StashEngine::User.create(first_name: 'Gorgonzola', last_name: 'Travesty', tenant_id: user.tenant_id, role: 'user')
        journal = Journal.create(title: 'Test Journal', issn: '1234-4321')
        InternalDatum.create(identifier_id: @identifier.id, data_type: 'publicationISSN', value: journal.single_issn)
        JournalRole.create(journal: journal, user: @user2, role: 'admin')

        expect(@resource.may_view?(ui_user: @user2)).to be_truthy
      end

      it 'allows curator to view anything' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(tenant_id: 'superca', meta_view: false, file_view: false)
        @user2 = StashEngine::User.create(first_name: 'Gorgonzola', last_name: 'Travesty', tenant_id: user.tenant_id, role: 'curator')
        expect(@resource.may_view?(ui_user: @user2)).to be_truthy
      end
    end

    describe :files_published? do

      before(:each) do
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI', pub_state: nil)
        @resource = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: true, file_view: false)
      end

      it 'defaults to false' do
        expect(@resource.files_published?).to eql(false)
      end

      it 'returns false for embargoes' do
        @identifier.update(pub_state: 'embargoed')
        @resource.reload
        expect(@resource.files_published?).to eq(false)
      end

      it 'returns true for published status' do
        @identifier.update(pub_state: 'published')
        @resource.update(file_view: true)
        @resource.reload
        expect(@resource.files_published?).to eq(true)
      end

      it 'returns false for unpublished status' do
        @identifier.update(pub_state: 'unpublished')
        @resource.reload
        expect(@resource.files_published?).to eq(false)
      end

      it 'returns false for other random status with file_view true' do
        # This scenario should probably not happen, but object status can override
        @identifier.update(pub_state: 'unpublished')
        @resource.update(file_view: true)
        @resource.reload
        expect(@resource.files_published?).to eq(false)
      end
    end

    describe :metadata_published? do

      before(:each) do
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI', pub_state: nil)
        @resource = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: false, file_view: false)
      end

      it 'defaults to false' do
        expect(@resource.metadata_published?).to eql(false)
      end

      it 'returns true for embargoed' do
        @identifier.update(pub_state: 'embargoed')
        @resource.update(meta_view: true)
        @resource.reload
        expect(@resource.metadata_published?).to eq(true)
      end

      it 'returns true for published' do
        @identifier.update(pub_state: 'published')
        @resource.update(meta_view: true)
        @resource.reload
        expect(@resource.metadata_published?).to eq(true)
      end

      it 'returns false for other random status' do
        @identifier.update(pub_state: 'unpublished')
        @resource.update(meta_view: true)
        @resource.reload
        expect(@resource.metadata_published?).to eq(false)
      end
    end

    describe '#previously_public?' do
      before(:each) do
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI', pub_state: nil)
      end

      it 'returns true if a previous resource had metadata view set to true' do
        @resource1 = Resource.create(user_id: user.id, created_at: '2020-01-03', identifier_id: @identifier.id, meta_view: true, file_view: false)
        @resource2 = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: false, file_view: false)
        # resource for different identifier, below
        Resource.create(user_id: user.id, meta_view: true, created_at: '2020-01-03', file_view: false)
        expect(@resource2.previously_public?).to eq(true)
      end

      it 'returns false if a previous resource had no metadata view exposed' do
        @resource1 = Resource.create(user_id: user.id, created_at: '2020-01-03', identifier_id: @identifier.id, meta_view: false, file_view: false)
        @resource2 = Resource.create(user_id: user.id, identifier_id: @identifier.id, meta_view: false, file_view: false)
        # resource for different identifier, below
        Resource.create(user_id: user.id, created_at: '2020-01-03', meta_view: true, file_view: false)
        expect(@resource2.previously_public?).to eq(false)
      end
    end

    describe '#zenodo_published?' do
      before(:each) do
        @resource = create(:resource, identifier: create(:identifier))
        create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                             state: 'finished', copy_type: 'software')
      end

      it 'detects if software has not been published, but just submitted' do
        expect(@resource.zenodo_published?).to be(false)
      end

      it 'detects if software has been published' do
        create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                             state: 'finished', copy_type: 'software_publish')
        expect(@resource.zenodo_published?).to be(true)
      end
    end

    describe '#zenodo_submitted?' do
      before(:each) do
        @resource = create(:resource, identifier: create(:identifier))
        create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier_id,
                             state: 'finished', copy_type: 'software')
      end

      it 'detects if software has been submitted' do
        expect(@resource.zenodo_submitted?).to be(true)
      end

      it "detects if software hasn't been successfully submitted" do
        @resource.zenodo_copies.first.update(state: 'error')
        expect(@resource.zenodo_submitted?).to be(false)
      end
    end

    describe 'self.need_publishing' do
      before(:each) do
        @identifier = create(:identifier)
        @resources = []
        @resource_states = []
        @curation_activities = []
        0.upto(3) do
          res = create(:resource, publication_date: Time.new - 1.day, identifier_id: @identifier.id)
          res.current_resource_state.update(resource_state: 'submitted')
          @curation_activities << [
            CurationActivity.create(status: 'submitted', resource_id: res.id, user: @user),
            CurationActivity.create(status: 'embargoed', resource_id: res.id, user: @user)
          ]
          @resources << res
        end
        # disqualify all of these from the query
        @resources[0].update(publication_date: Time.new + 1.day) # get rid of time expired on first one
        @curation_activities[1][1].destroy! # get rid of embargoed on this one
        @resources[2].current_resource_state.update(resource_state: 'in_progress')
      end

      it 'returns only items that have been published to merritt, curation status embargoed, and embargo date passed' do
        items = StashEngine::Resource.need_publishing
        expect(items.count).to eq(1) # only the last should be able to be changed
        expect(items.first.id).to eq(@resources[3].id) # only last one should be eligible
      end
    end

    describe :ensure_state_and_version do
      attr_reader :resource
      attr_reader :orig_state_id
      attr_reader :orig_version
      before(:each) do
        @resource = create(:resource, user_id: user.id)
        @orig_state_id = resource.current_resource_state_id
        @orig_version = resource.stash_version
      end

      it 'inits version if not present' do
        resource.stash_version&.delete
        resource.stash_version = nil
        resource.ensure_state_and_version

        expect(resource.current_resource_state_id).to eq(orig_state_id) # shouldn't change

        expect(resource.stash_version).not_to be_nil
        expect(resource.stash_version).not_to eq(orig_version)
      end

      it 'inits state if not present' do
        resource.current_resource_state_id = nil
        resource.ensure_state_and_version

        expect(resource.stash_version).to eq(orig_version) # shouldn't change

        expect(resource.current_resource_state_id).not_to be_nil
        expect(resource.current_resource_state_id).not_to eq(orig_state_id)
      end
    end

    describe 'author' do
      attr_reader :resource
      before(:each) do
        @resource = create(:resource, user_id: user.id)
      end

      it 'allows multiple authors' do
        author1 = create(:author,
                         resource_id: resource.id,
                         author_first_name: 'Lise',
                         author_last_name: 'Meitner',
                         author_email: 'lmeitner@example.edu',
                         author_orcid: '0000-0003-4293-0137')
        author2 = create(:author,
                         resource_id: resource.id,
                         author_first_name: 'Albert',
                         author_last_name: 'Einstein',
                         author_email: 'bigal@example.edu',
                         author_orcid: '0000-0001-8528-2091')
        expect(resource.authors).to include(author1, author2)
      end

      it 'checks owner_author by matching orcid' do
        expect(@resource.owner_author).to eq(@resource.authors.first)

        @resource.authors.first.update(author_orcid: '1234-1234-1234-1234')
        expect(@resource.owner_author).to be_nil
      end

      describe 'amoeba duplication' do
        attr_reader :authors

        # Add two authors, in addition to the author that is
        # created default with the resource.
        before(:each) do
          @authors = [
            create(:author,
                   resource_id: resource.id,
                   author_first_name: 'Lise',
                   author_last_name: 'Meitner',
                   author_email: 'lmeitner@example.edu',
                   author_orcid: '0000-0003-4293-0137'),
            create(:author,
                   resource_id: resource.id,
                   author_first_name: 'Albert',
                   author_last_name: 'Einstein',
                   author_email: 'bigal@example.edu',
                   author_orcid: '0000-0001-8528-2091')
          ]
        end

        it 'copies authors' do
          old_authors = resource.authors.to_a
          expect(Author.count).to eq(3) # just to be sure
          expect(old_authors.size).to eq(3) # just to be sure

          new_resource = resource.amoeba_dup
          new_resource.save!
          expect(Author.count).to eq(6)

          new_authors = new_resource.authors.to_a
          expect(new_authors.size).to eq(3)
          new_authors.each_with_index do |author, i|
            expect(author.id).not_to eq(old_authors[i].id)
            expect(author.resource_id).to eq(new_resource.id)
            expect(author.author_first_name).to eq(old_authors[i].author_first_name)
            expect(author.author_last_name).to eq(old_authors[i].author_last_name)
            expect(author.author_email).to eq(old_authors[i].author_email)
            expect(author.author_orcid).to eq(old_authors[i].author_orcid)
          end
        end
      end
    end

    describe '#purge_duplicate_subjects!' do
      before(:each) do
        @resource = create(:resource)
      end

      it 'purges duplicate subjects' do
        @resource.subjects << create(:subject, subject: 'AARDVARKS')
        @resource.subjects << create(:subject, subject: 'Aardvarks')
        @resource.subjects << create(:subject, subject: 'aardvarks')
        starting_size = @resource.subjects.count
        @resource.purge_duplicate_subjects!
        expect(@resource.reload.subjects.count).to eq(starting_size - 2)
      end

      it "doesn't purge FOS subjects" do
        existing_fos = @resource.subjects.fos.first
        @resource.subjects << create(:subject, subject: existing_fos.subject) # this one doesn't have fos subject_scheme set
        @resource.subjects << create(:subject, subject: existing_fos.subject)
        starting_size = @resource.subjects.count
        @resource.purge_duplicate_subjects!
        @resource.reload
        expect(@resource.subjects.count).to eq(starting_size - 1) # only purges one
        expect(@resource.subjects.fos.count).to eq(1) # still has the one FOS subject
        expect(@resource.subjects.non_fos.where(subject: existing_fos.subject).count).to eq(1) # still has that subject in non-FOS, also
      end

      it 'prefers to purge non-controlled vocab subjects over ones with vocabulary' do
        existing_subj = @resource.subjects.non_fos.first
        @resource.subjects << create(:subject, subject: existing_subj.subject, subject_scheme: 'gumma')
        starting_size = @resource.subjects.count
        @resource.purge_duplicate_subjects!
        @resource.reload
        expect(@resource.subjects.count).to eq(starting_size - 1) # only purges one
        left_subject = @resource.subjects.where(subject: existing_subj.subject)
        expect(left_subject.count).to eq(1) # still has that subject
        expect(left_subject.first.subject_scheme).to eq('gumma') # it kept the one with a subject scheme
      end
    end

    describe 'resource state' do
      attr_reader :resource
      attr_reader :state
      before(:each) do
        allow_any_instance_of(Resource).to receive(:prepare_for_curation).and_return(true)
        @resource = create(:resource, user_id: user.id)
        @state = ResourceState.find_by(resource_id: resource.id)
      end

      describe :init_state do
        it 'initializes the state to in_progress' do
          expect(state.resource_state).to eq('in_progress')
        end
        it 'sets the user ID' do
          expect(state.user_id).to eq(user.id)
        end
      end

      describe :current_state= do
        it 'sets the state' do
          new_state_value = 'submitted'
          resource.current_state = new_state_value
          new_state = resource.current_resource_state
          expect(new_state.resource_state).to eq(new_state_value)
        end
        it 'doesn\'t create unnecesary values' do
          state = resource.current_resource_state
          expect(ResourceState.count).to eq(1)
          resource.current_state = 'in_progress'
          expect(ResourceState.count).to eq(1)
          expect(resource.current_resource_state).to eq(state)
        end
        describe 'amoeba duplication' do
          it 'defaults to in-progress' do
            resource.current_state = 'submitted'
            res1 = resource.amoeba_dup
            res1.save!
            expect(res1.current_state).to eq('in_progress')
          end
          it 'creates a new instance' do
            resource.current_state = 'submitted'
            res1 = resource.amoeba_dup
            res1.save!
            res1.current_state = 'error'
            expect(res1.current_state).to eq('error')
            expect(resource.current_state).to eq('submitted')
          end
          it 'does not call prepare_for_curation when :in_progress' do
            resource.preserve_curation_status = true
            expect(resource).not_to receive(:prepare_for_curation)
            resource.current_state = 'in_progress'
          end
          it 'does not call prepare_for_curation when `preserve_curation_status == true`' do
            resource.preserve_curation_status = true
            expect(resource).not_to receive(:prepare_for_curation)
            resource.current_state = 'submitted'
          end
        end
      end

      describe :current_resource_state do
        it 'returns the initial state' do
          expect(state).not_to be_nil # just to be sure
          expect(resource.current_resource_state).to eq(state)
        end

        it 'reflects state changes' do
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            new_state = resource.current_resource_state
            expect(new_state.resource_state).to eq(state_value)
          end
        end

        it 'is not copied or clobbered in Amoeba duplication' do
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            new_resource = resource.amoeba_dup
            new_resource.save!

            new_resource_state = new_resource.current_resource_state
            expect(new_resource_state.resource_id).to eq(new_resource.id)
            expect(new_resource_state.resource_state).to eq('in_progress')

            orig_resource_state = resource.current_resource_state
            expect(orig_resource_state.resource_id).to eq(resource.id)
            expect(orig_resource_state.resource_state).to eq(state_value)
          end
        end
      end

      describe :submitted? do
        it 'returns true if the current state is published' do
          resource.current_state = 'submitted'
          expect(resource.submitted?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.submitted?).to eq(false)
          %w[in_progress processing error].each do |state_value|
            resource.current_state = state_value
            expect(resource.submitted?).to eq(false)
          end
        end
      end

      describe :processing? do
        it 'returns true if the current state is processing' do
          resource.current_state = 'processing'
          expect(resource.processing?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.processing?).to eq(false)
          %w[in_progress submitted error].each do |state_value|
            resource.current_state = state_value
            expect(resource.processing?).to eq(false)
          end
        end
      end

      describe :current_state do
        it 'returns the value of the current state' do
          expect(resource.current_state).to eq('in_progress')
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            expect(resource.current_state).to eq(state_value)
          end
        end
      end
    end

    describe 'data filess' do

      describe :current_file_uploads do
        attr_reader :created_files
        attr_reader :copied_files
        attr_reader :deleted_files
        before(:each) do
          @res1 = create(:resource, user_id: user.id)

          @created_files = Array.new(3) do |i|
            DataFile.create(
              resource: @res1,
              file_state: 'created',
              upload_file_name: "created#{i}.bin",
              upload_file_size: i * 3
            )
          end
          @copied_files = Array.new(3) do |i|
            DataFile.create(
              resource: @res1,
              file_state: 'copied',
              upload_file_name: "copied#{i}.bin",
              upload_file_size: i * 5
            )
          end
          @deleted_files = Array.new(3) do |i|
            DataFile.create(
              resource: @res1,
              file_state: 'deleted',
              upload_file_name: "deleted#{i}.bin",
              upload_file_size: i * 7
            )
          end
        end

        it 'defaults to empty' do
          res2 = create(:resource, user_id: user.id)
          expect(res2.current_file_uploads).to be_empty
        end

        it 'includes created and copied' do
          current = @res1.current_file_uploads
          created_files.each { |f| expect(current).to include(f) }
          copied_files.each { |f| expect(current).to include(f) }
          deleted_files.each { |f| expect(current).not_to include(f) }
        end

        describe 'amoeba duplication' do
          before(:each) do
            @res2 = @res1.amoeba_dup
          end

          it 'copies the non-deleted records' do
            created_and_copied = (created_files + copied_files).map(&:upload_file_name)
            new_names = @res2.data_files.map(&:upload_file_name)
            expect(new_names).to match_array(created_and_copied)
          end

          it 'copies all current records' do
            old_current_names = @res1.current_file_uploads.map(&:upload_file_name)
            new_current_names = @res2.current_file_uploads.map(&:upload_file_name)
            expect(new_current_names).to match_array(old_current_names)
          end

          it 'sets all current records to "copied"' do
            @res2.current_file_uploads.each { |f| expect(f.file_state).to eq('copied') }
          end

          it 'doesn\'t copy deleted files' do
            expect(@res2.data_files.deleted).to be_empty
          end
        end

        describe :size do
          it 'includes all copied and created' do
            created_size = created_files.inject(0) { |sum, f| sum + f.upload_file_size }
            copied_size = copied_files.inject(0) { |sum, f| sum + f.upload_file_size }
            expected_size = created_size + copied_size
            expect(@res1.size).to eq(expected_size)
          end
        end

        describe :upload_type do
          it 'returns :unknown for no uploads' do
            @res1.data_files.delete_all
            expect(@res1.upload_type).to eq(:unknown)
          end

          it 'returns :files for files' do
            expect(@res1.upload_type).to eq(:files)
          end

          it 'returns :manifest if at least one new file has a URL' do
            a_file = created_files[2]
            a_file.url = 'http://example.org/foo.bar'
            a_file.status_code = 200
            a_file.save

            expect(@res1.upload_type).to eq(:manifest)
          end
        end

        describe :new_data_files do
          it 'defaults to empty' do
            res3 = create(:resource, user_id: user.id)
            expect(res3.new_data_files).to be_empty
          end

          it 'includes only created' do
            new = @res1.new_data_files
            created_files.each { |f| expect(new).to include(f) }
            copied_files.each { |f| expect(new).not_to include(f) }
            deleted_files.each { |f| expect(new).not_to include(f) }
          end
        end
      end

      describe :data_files do
        before(:each) do
          @resource = create(:resource)
          @uploads = Array.new(3) do |_i|
            create(:data_file,
                   resource: @resource,
                   file_state: :created)
          end
        end

        describe :latest_file_states do
          it 'finds the latest version of each file' do
            # add copies of these files to the resource
            new_latest = @uploads.each_with_index.map do |f, _i|
              create(:data_file,
                     resource: f.resource,
                     upload_file_name: f.upload_file_name,
                     file_state: :copied)
            end
            @resource.reload
            latest = @resource.latest_file_states
            expect(latest.count).to eq(new_latest.size)
            latest.each { |upload| expect(new_latest).to include(upload) }
          end
        end

        describe :duplicate_filenames do
          it 'identifies duplicate files' do
            original = @uploads[0]
            file_name = original.upload_file_name
            duplicate = create(:data_file,
                               resource_id: @resource.id,
                               upload_file_name: file_name,
                               file_state: :created)
            duplicates = @resource.duplicate_filenames
            expect(duplicates.count).to eq(2)
            expect(duplicates).to include(original)
            expect(duplicates).to include(duplicate)
          end
        end

        describe :url_in_version? do
          it 'returns false if not present' do
            expect(@resource.url_in_version?(url: 'http://example.org/')).to eq(false)
          end

          it 'returns true if present' do
            upload = @uploads[0]
            upload.url = 'http://example.org/'
            upload.status_code = 200
            upload.save

            expect(@resource.url_in_version?(url: 'http://example.org/')).to eq(true)
          end
        end
      end
    end

    describe 'versioning' do
      attr_reader :resource
      before(:each) do
        @resource = create(:resource)
      end

      describe :stash_version do
        it 'is initialized' do
          expect(resource.stash_version).not_to be_nil
        end
      end

      describe :version_number do
        it 'defaults to 1' do
          expect(resource.version_number).to eq(1)
        end
      end

      describe :merritt_version do
        it 'defaults to 1' do
          expect(resource.merritt_version).to eq(1)
        end
      end

      describe :version_zipfile= do
        it 'creates the first version' do
          zipfile = '/apps/uploads/17-archive.zip'
          resource.version_zipfile = zipfile
          version = StashEngine::Version.find_by(resource_id: resource.id)
          expect(version).not_to be_nil
          expect(version.zip_filename).to eq('17-archive.zip')
          expect(version.version).to eq(1)
        end
      end

      describe 'identifier interaction' do
        before(:each) do
          # TODO: collapse this into single method on resource
          resource.current_state = 'submitted'
          resource.version_zipfile = "#{resource.id}-archive.zip"
        end

        describe :version_number do
          it 'still defaults to 1' do
            expect(resource.version_number).to eq(1)
          end

          it 'is incremented for the next resource by Amoeba duplication' do
            new_resource = resource.amoeba_dup
            new_resource.save!
            expect(new_resource.version_number).to eq(2)

            newer_resource = new_resource.amoeba_dup
            newer_resource.save!
            expect(newer_resource.version_number).to eq(2)
          end

          it 'is incremented for the next resource' do
            new_resource = create(:resource, identifier: resource.identifier)
            expect(new_resource.version_number).to eq(2)
          end
        end

        describe :merritt_version do
          it 'still defaults to 1' do
            expect(resource.merritt_version).to eq(1)
          end

          it 'is incremented for the next resource by Amoeba duplication' do
            new_resource = resource.amoeba_dup
            new_resource.save!
            expect(new_resource.merritt_version).to eq(2)
          end

          it 'is incremented for the next resource' do
            new_resource = create(:resource, identifier: resource.identifier)
            expect(new_resource.merritt_version).to eq(2)
          end
        end

        describe :next_version_number do
          it 'is based on the last submitted version' do
            expect(resource.next_version_number).to eq(2)
          end
        end

        describe :next_merritt_version do
          it 'is based on the last submitted version' do
            expect(resource.next_merritt_version).to eq(2)
          end
        end

        describe :latest_per_dataset do
          it 'only returns latest resources and new resources' do
            resource.dup.save
            create(:resource)
            expect(Resource.latest_per_dataset.count).to eq(2)
          end
        end
      end
    end

    describe 'identifiers' do
      attr_reader :resource
      before(:each) do
        @existing_ident = create(:identifier, identifier_type: 'DOI')
        @doi_value = @existing_ident.identifier
        @resource = create(:resource, identifier: @existing_ident, user_id: user.id)
      end

      describe :ensure_identifier do
        it 'sets the identifier value' do
          resource.ensure_identifier(@doi_value)
          ident = resource.identifier
          expect(ident).not_to be_nil
          expect(ident.identifier_type).to eq('DOI')
          expect(ident.identifier).to eq(@doi_value)
        end

        it 'works with or without "doi:" prefix' do
          resource.ensure_identifier("doi:#{@doi_value}")
          ident = resource.identifier
          expect(ident).not_to be_nil
          expect(ident.identifier_type).to eq('DOI')
          expect(ident.identifier).to eq(@doi_value)
        end

        it 'raises an error if the resource already has a different identifier' do
          resource.ensure_identifier(@doi_value)
          expect { resource.ensure_identifier('10.345/678') }.to raise_error(ArgumentError)
          expect(Identifier.count).to eq(1)
          expect(resource.identifier_value).to eq(@doi_value)
        end

        it 'doesn\'t create extra identifier records' do
          4.times do |_|
            @resource.ensure_identifier(@doi_value)
          end
          expect(Identifier.count).to eq(1)
          expect(@resource.identifier).to eq(@existing_ident)
        end
      end

      describe :identifier_str do
        it 'returns the full DOI' do
          resource.ensure_identifier(@doi_value)
          expect(resource.identifier_str).to eq("doi:#{@doi_value}")
        end
      end

      describe :identifier_uri do
        it 'returns the doi.org URL' do
          resource.ensure_identifier(@doi_value)
          expect(resource.identifier_uri).to eq("https://doi.org/#{@doi_value}")
        end
      end

      describe 'amoeba duplication' do
        it 'preserves the identifier' do
          resource.ensure_identifier(@doi_value)
          res2 = resource.amoeba_dup
          expect(res2.identifier_str).to eq("doi:#{@doi_value}")
        end
      end
    end

    describe 'statistics' do
      describe :submitted_dataset_count do
        before(:each) do
          allow_any_instance_of(Resource).to receive(:prepare_for_curation).and_return(true)
        end

        it 'defaults to zero' do
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'counts published current states' do
          3.times do |index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'submitted'
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(3)
        end
        it 'groups by identifier' do
          ident1 = create(:identifier)
          ident2 = create(:identifier)
          3.times do |_index|

            res1 = create(:resource, identifier: ident1, user_id: user.id)
            res1.current_state = 'submitted'
            res1.save
            res2 = create(:resource, identifier: ident2, user_id: user.id)
            res2.current_state = 'submitted'
            res2.save
          end
          expect(Resource.submitted_dataset_count).to eq(2)
        end

        it 'doesn\'t count non-published datasets' do
          %w[in_progress processing error].each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'doesn\'t count non-current states' do
          %w[in_progress processing error].each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'submitted'
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
      end
    end

    describe 'curation helpers' do

      before(:each) do
        @identifier = create(:identifier)
      end

      describe :init_curation_status do

        it 'has a curation activity record when created' do
          resource = create(:resource, identifier: @identifier, user_id: user.id)
          resource.reload
          expect(resource.curation_activities.empty?).to eql(false)
          expect(resource.last_curation_activity.id).to eql(CurationActivity.last.id)
          expect(resource.current_curation_status).to eql('in_progress')
        end

      end

      describe :curatable? do

        it 'is false when current_resource_state != "submitted"' do
          resource = create(:resource, user_id: user.id)
          resource.current_state = 'in_progress'
          expect(resource.reload.curatable?).to eql(false)
          resource.current_state = 'processing'
          expect(resource.reload.curatable?).to eql(false)
          resource.current_state = 'error'
          expect(resource.reload.curatable?).to eql(false)
        end

        it 'is false even when current curation state is Submitted' do
          identifier = create(:identifier, identifier_type: 'DOI', identifier: '10.999/999')
          resource = create(:resource, user_id: user.id, identifier_id: identifier.id)
          CurationActivity.create(resource_id: resource.id, status: 'submitted')
          resource.reload
          expect(resource.curatable?).to eql(false)
        end

        it 'is true when current_resource_state == "submitted"' do
          allow_any_instance_of(Resource).to receive(:prepare_for_curation).and_return(true)
          resource = create(:resource, user_id: user.id)
          resource.current_state = 'submitted'
          expect(resource.reload.curatable?).to eql(true)
        end
      end

      describe :submitted_date_curation_date do

        it 'returns the correct dates for a regular submission' do
          res = create(:resource, user_id: @user.id, tenant_id: @user.tenant_id)
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-01', status: 'in_progress')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-02', status: 'submitted')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-03', status: 'submitted')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-04', status: 'published')
          expect(res.submitted_date.to_date).to eql(Date.parse('2020-01-02'))
          expect(res.curation_start_date.to_date).to eql(Date.parse('2020-01-02'))
        end

        it 'returns the correct dates when an item went straight from peer_review to curation' do
          res = create(:resource, user_id: @user.id, tenant_id: @user.tenant_id)
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-01', status: 'in_progress')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-02', status: 'peer_review')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-03', status: 'curation')
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-04', status: 'published')
          expect(res.submitted_date.to_date).to eql(Date.parse('2020-01-02'))
          expect(res.curation_start_date.to_date).to eql(Date.parse('2020-01-03'))
        end

        it 'returns nil if there is no submitted_date' do
          res = create(:resource, user_id: @user.id, tenant_id: @user.tenant_id)
          create(:curation_activity_no_callbacks, resource: res, created_at: '2020-01-01', status: 'in_progress')
          expect(res.submitted_date).to be_nil
          expect(res.curation_start_date).to be_nil
        end
      end

      describe :curation_visibility_setup do

        before(:each) do
          # user has only user permission and is part of the UCOP tenant
          @user2 = create(:user, first_name: 'Gargola', last_name: 'Jones', email: 'luckin@ucop.edu', tenant_id: 'ucop', role: 'admin')
          @user3 = create(:user, first_name: 'Merga', last_name: 'Flav', email: 'flavin@ucop.edu', tenant_id: 'ucb', role: 'curator')
          @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
          @resources = [create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifier.id),
                        create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifier.id)]

          @curation_activities = [[create(:curation_activity_no_callbacks, resource: @resources[0], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[0], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[0], status: 'published')]]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[1], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[1], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[1], status: 'embargoed')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[2], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[2], status: 'curation')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[3], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[3], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[3], status: 'action_required')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[4], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[4], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[4], status: 'published')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[5], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[5], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[5], status: 'embargoed')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[6], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[6], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[6], status: 'withdrawn')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[7], status: 'in_progress')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[8], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[8], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[8], status: 'published')]

          @curation_activities << [create(:curation_activity_no_callbacks, resource: @resources[9], status: 'in_progress'),
                                   create(:curation_activity_no_callbacks, resource: @resources[9], status: 'curation'),
                                   create(:curation_activity_no_callbacks, resource: @resources[9], status: 'embargoed')]

          # 6 publicly viewable
          # admin for UCOP (user2) can see 6 public + 2 extras for other private ucop datasets

        end

        describe :with_visibility do
          it 'lists publicly viewable (two curation states) in one query' do
            public_resources = Resource.with_visibility(states: %w[published embargoed])
            expect(public_resources.count).to eq(6)
            expect(public_resources.map(&:id)).to include(@resources[0].id)
          end

          it 'lists publicly viewable and private in my tenant for admins' do
            resources = Resource.with_visibility(states: %w[published embargoed], user_id: nil, tenant_id: 'ucop')
            expect(resources.count).to eq(8)
            expect(resources.map(&:id)).to include(@resources[3].id)
          end

          it 'lists publicly viewable and my own datasets for a user' do
            resources = Resource.with_visibility(states: %w[published embargoed], user_id: @user.id)
            expect(resources.count).to eq(7)
            expect(resources.map(&:id)).to include(@resources[2].id)
          end

          it 'only picks up the final state for each dataset' do
            resources = Resource.with_visibility(states: 'curation')
            expect(resources.count).to eq(1)
            expect(resources.map(&:id)).to include(@resources[2].id)
          end
        end

        # this can test more or less the same stuff as "with visibility" but automatically modifies for the user and
        # their role.  I think will mostly be used for getting resources for an identifier visible to a user and their role.
        describe :visible_to_user do
          before(:each) do
            @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
            @resources[0].update(identifier_id: @identifier.id)
            @resources[1].update(identifier_id: @identifier.id)
            @resources[2].update(identifier_id: @identifier.id)
          end

          it 'shows all resources for the identifier to the curator' do
            resources = StashEngine::ResourcePolicy::VersionScope.new(@user3, @identifier.resources).resolve
            expect(resources.count).to eq(3)
          end

          it 'shows all resources to the owner' do
            resources = StashEngine::ResourcePolicy::VersionScope.new(@user3, @identifier.resources).resolve
            expect(resources.count).to eq(3)
          end

          it 'only shows curated-visible resources to a non-user' do
            resources = StashEngine::ResourcePolicy::VersionScope.new(nil, @identifier.resources).resolve
            expect(resources.count).to eq(2)
          end

          it 'shows all resources to an admin for this tenant (ucop)' do
            resources = StashEngine::ResourcePolicy::VersionScope.new(@user2, @identifier.resources).resolve
            expect(resources.count).to eq(3)
          end

          it 'shows all resources to an admin for this journal' do
            journal = Journal.create(title: 'Test Journal', issn: '1234-4321')
            InternalDatum.create(identifier_id: @identifier.id, data_type: 'publicationISSN', value: journal.single_issn)
            JournalRole.create(journal: journal, user: @user2, role: 'admin')
            resources = StashEngine::ResourcePolicy::VersionScope.new(@user2, @identifier.resources).resolve
            expect(resources.count).to eq(3)
          end

          it 'only shows curated-visible resources to a random user' do
            @user4 = create(:user, first_name: 'Gorgon', last_name: 'Grup', email: 'st38p@ucop.edu', tenant_id: 'ucb', role: 'user')
            resources = StashEngine::ResourcePolicy::VersionScope.new(@user4, @identifier.resources).resolve
            expect(resources.count).to eq(2)
          end
        end
      end
    end

    describe '#send_to_zenodo' do

      before(:each) do
        # This is all horribly hacky because of the way these tests don't load Rails correctly, we need move tests to
        # a real Rails environment.

        require_relative '../../../app/jobs/stash_engine/zenodo_copy_job'

        @resource = create(:resource)
        create(:data_file, resource_id: @resource.id)
      end

      it 'creates a zenodo_copy record in database' do
        allow(ZenodoCopyJob).to receive(:perform_later).and_return(nil)
        @resource.send_to_zenodo
        @resource.reload
        expect(@resource.zenodo_copies.data.first).not_to be_nil
        expect(@resource.zenodo_copies.data.first.state).to eq('enqueued')
      end

      it 'calls perform_later' do
        expect(ZenodoCopyJob).to receive(:perform_later).with(@resource.id)
        @resource.send_to_zenodo
      end

      it "doesn't call perform_later if non-finished copy exists and not enqueued" do
        expect(ZenodoCopyJob).to_not receive(:perform_later).with(@resource.id)
        ZenodoCopy.create(state: 'replicating', identifier_id: @resource.identifier.id, resource_id: @resource.id, copy_type: 'data', note: '')
        @resource.send_to_zenodo
      end

    end

    describe '#previous_resource' do
      before(:each) do
        @identifier2 = Identifier.create(identifier: 'cat/frog', identifier_type: 'DOI')
        @identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')

        @resource1 = Resource.create(user_id: user.id, identifier_id: @identifier.id)
        @other_resource1 = Resource.create(user_id: user.id, identifier_id: @identifier2.id)
        @resource2 = Resource.create(user_id: user.id, identifier_id: @identifier.id)
        @resource3 = Resource.create(user_id: user.id, identifier_id: @identifier.id)
      end

      it 'has no previous resource for version 1' do
        expect(@resource1.previous_resource).to be_nil
      end

      it 'shows version 1 is previous resource for version 2' do
        expect(@resource2.previous_resource).to eq(@resource1)
      end

      it 'shows version 2 as previous resource for version 3' do
        expect(@resource3.previous_resource).to eq(@resource2)
      end
    end

  end
end
