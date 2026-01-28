# == Schema Information
#
# Table name: stash_engine_identifiers
#
#  id                      :integer          not null, primary key
#  deleted_at              :datetime
#  downloaded_at           :datetime
#  edit_code               :string(191)
#  identifier              :text(65535)
#  identifier_type         :text(65535)
#  import_info             :integer
#  issues                  :json
#  last_invoiced_file_size :bigint
#  old_payment_system      :boolean          default(FALSE)
#  payment_type            :string(191)
#  pub_state               :string
#  publication_date        :datetime
#  search_words            :text(65535)
#  storage_size            :bigint
#  waiver_basis            :string(191)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  latest_resource_id      :integer
#  license_id              :string(191)
#  payment_id              :text(65535)
#  software_license_id     :integer
#
# Indexes
#
#  admin_search_index                                     (search_words)
#  index_stash_engine_identifiers_on_deleted_at           (deleted_at)
#  index_stash_engine_identifiers_on_identifier           (identifier)
#  index_stash_engine_identifiers_on_latest_resource_id   (latest_resource_id)
#  index_stash_engine_identifiers_on_license_id           (license_id)
#  index_stash_engine_identifiers_on_software_license_id  (software_license_id)
#
require 'webmock/rspec'
require 'byebug'

module StashEngine
  describe Identifier, type: :model do
    include Mocks::Aws
    include Mocks::CurationActivity
    include Mocks::Datacite
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    before(:each) do
      mock_aws!
      mock_solr!
      mock_datacite!
      mock_salesforce!
      mock_stripe!
      neuter_emails!
      create(:tenant_ucop)
      @user = create(:user, tenant_id: 'dryad')
      Timecop.travel(Time.now.utc - 3.minutes)
      @identifier = create(:identifier, identifier_type: 'DOI', identifier: '10.123/456')
      @res1 = create(:resource, identifier_id: @identifier.id, user: @user, tenant_id: 'dryad')
      Timecop.travel(Time.now.utc + 1.minute)
      @res2 = create(:resource, identifier_id: @identifier.id, user: @user, tenant_id: 'dryad')
      Timecop.travel(Time.now.utc + 1.minute)
      @res3 = create(:resource, identifier_id: @identifier.id, user: @user, tenant_id: 'dryad')
      Timecop.return
      @created_files = Array.new(3) do |i|
        DataFile.create(
          resource: @res3,
          file_state: 'created',
          download_filename: "created#{i}.bin",
          upload_file_size: i * 3
        )
      end
      @res1.current_state = 'submitted'
      create(:version, resource_id: @res1.id, version: 1)
      @res2.current_state = 'submitted'
      create(:version, resource_id: @res2.id, version: 2)
      @res3.current_state = 'in_progress'
      create(:version, resource_id: @res3.id, version: 3)

      @identifier.reload
      @fake_issn = '1234-000X'
      @fake_manuscript_number = 'bogus-manuscript-number'
      @pub = create(:resource_publication, resource_id: @identifier.latest_resource_id, publication_issn: @fake_issn,
                                           manuscript_number: @fake_manuscript_number)

      @identifier.reload
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    after(:each) do
      WebMock.allow_net_connect!
    end

    describe '#to_s' do
      it 'returns something useful' do
        expect(@identifier.to_s).to eq('doi:10.123/456')
      end
    end

    describe 'versioning' do

      describe '#first_submitted_resource' do
        it 'returns the first submitted version' do
          lsv = @identifier.first_submitted_resource
          expect(lsv.id).to eq(@res1.id)
        end
      end

      describe '#last_submitted_resource' do
        it 'returns the last submitted version' do
          lsv = @identifier.last_submitted_resource
          expect(lsv.id).to eq(@res2.id)
        end
      end

      describe '#latest_resource' do
        it 'returns the latest resource' do
          expect(@identifier.latest_resource_id).to eq(@res3.id)
        end
      end

      describe '#most_recent_curator' do
        it 'finds the most recent curator' do
          user = create(:user)
          cur1 = create(:user, role: 'curator')
          cur2 = create(:user, role: 'curator')
          @res3.update(current_editor_id: user.id)
          @res2.update(current_editor_id: cur1.id)
          @res1.update(current_editor_id: cur2.id)
          @identifier.reload
          expect(@identifier.most_recent_curator).to eq(cur1)
        end

        it 'returns nil when there is no curator' do
          user = create(:user)
          @res3.update(current_editor_id: user.id)
          @res2.update(current_editor_id: user.id)
          @res1.update(current_editor_id: user.id)
          @identifier.reload
          expect(@identifier.most_recent_curator).to be_nil
        end
      end

      describe '#in_progress_resource' do
        it 'returns the in-progress version' do
          ipv = @identifier.in_progress_resource
          expect(ipv.id).to eq(@res3.id)
        end
      end

      describe '#in_progress?' do
        it 'returns true if an in-progress version exists' do
          expect(@identifier.in_progress?).to eq(true)
        end
        it 'returns false if no in-progress version exists' do
          @res3.current_state = 'submitted'
          expect(@identifier.in_progress?).to eq(false)
        end
      end

      describe '#processing_resource' do
        before(:each) do
          @res2.current_state = 'processing'
        end

        it 'returns the "processing" version' do
          pv = @identifier.processing_resource
          expect(pv.id).to eq(@res2.id)
        end
      end

      describe '#processing?' do
        it 'returns false if no "processing" version exists' do
          expect(@identifier.processing?).to eq(false)
        end

        it 'returns true if a "processing" version exists' do
          @res2.current_state = 'processing'
          expect(@identifier.processing?).to eq(true)
        end
      end

      describe '#error?' do
        it 'returns false if no "error" version exists' do
          expect(@identifier.error?).to eq(false)
        end

        it 'returns true if a "error" version exists' do
          @res2.current_state = 'error'
          expect(@identifier.error?).to eq(true)
        end
      end

      # TODO: in progress is just the in-progress state itself of the group of in_progress states.  We need to fix our terminology.
      describe '#in_progress_only?' do
        it 'returns false if no "in_progress_only" version exists' do
          @res3.current_state = 'submitted'
          expect(@identifier.in_progress_only?).to eq(false)
        end

        it 'returns true if a "in_progress_only" version exists' do
          @res2.current_state = 'error'
          expect(@identifier.in_progress_only?).to eq(true)
        end
      end

      describe '#resources.with_file_changes' do
        before(:each) do
          DataFile.create(resource_id: @res1.id, download_filename: 'cat', file_state: 'created')
          DataFile.create(resource_id: @res2.id, download_filename: 'cat', file_state: 'copied')
          DataFile.create(resource_id: @res3.id, download_filename: 'cat', file_state: 'created')
        end

        it 'returns the version that changed' do
          resources = @identifier.resources.with_file_changes.distinct
          expect(resources.first.id).to eq(@res1.id)
          expect(resources.count).to eq(2)
        end
      end

      describe 'curation activity setup' do
        before(:each) { neuter_curation_callbacks! }

        describe '#approval_date' do
          it 'selects the correct approval_date' do
            target_date = DateTime.new(2010, 2, 3).utc
            CurationService.new(resource: @res1, status: 'curation', user: @user, created_at: '2000-01-01').process
            CurationService.new(resource: @res1, status: 'published', user: @user, created_at: target_date).process
            CurationService.new(resource: @res1, status: 'published', user: @user, created_at: '2020-01-01').process
            expect(@identifier.approval_date).to eq(target_date)
          end

          it 'gives no approval_date for unpublished items' do
            CurationService.new(status: 'curation', user: @user, resource: @res1, created_at: '2000-01-01').process
            expect(@identifier.approval_date).to eq(nil)
          end
        end

        describe '#curation_completed_date' do
          it 'selects the correct curation_completed_date' do
            target_date = DateTime.new(2010, 2, 3).utc
            CurationService.new(status: 'curation', user: @user, created_at: '2000-01-01', resource: @res1).process
            CurationService.new(status: 'action_required', user: @user, created_at: target_date, resource: @res1).process
            CurationService.new(status: 'published', user: @user, created_at: '2020-01-01', resource: @res1).process
            expect(@identifier.curation_completed_date).to eq(target_date)
          end

          it 'gives no curation_completed_date for items still in curation' do
            CurationService.new(status: 'curation', user: @user, resource: @res1, created_at: '2000-01-01').process
            expect(@identifier.curation_completed_date).to eq(nil)
          end
        end

        describe '#date_last_curated' do
          it 'selects the correct date_last_curated' do
            target_date = DateTime.new(2010, 2, 3).utc
            CurationService.new(resource: @res1, status: 'queued', user: @user, created_at: '2000-01-01').process
            CurationService.new(resource: @res1, status: 'curation', user: @user, created_at: target_date).process
            CurationService.new(resource: @res2, status: 'queued', user: @user, created_at: '2020-01-01').process
            CurationService.new(resource: @res3, status: 'queued', user: @user, created_at: '2030-01-01').process
            expect(@identifier.date_last_curated).to eq(target_date)
          end

          it 'gives no date_last_curated for uncurated items' do
            CurationService.new(resource: @res1, status: 'queued', user: @user, created_at: '2000-01-01').process
            CurationService.new(resource: @res1, status: 'peer_review', user: @user, created_at: '2010-01-01').process
            CurationService.new(resource: @res2, status: 'queued', user: @user, created_at: '2020-01-01').process
            CurationService.new(resource: @res3, status: 'queued', user: @user, created_at: '2030-01-01').process
            expect(@identifier.date_last_curated).to eq(nil)
          end
        end

        describe '#latest_resource_with_public_metadata' do

          it 'finds the last published resource' do
            CurationService.new(resource: @res1, status: 'curation', user: @user).process
            CurationService.new(resource: @res1, status: 'published', user: @user).process
            CurationService.new(resource: @res2, status: 'curation', user: @user).process
            CurationService.new(resource: @res2, status: 'published', user: @user).process
            CurationService.new(resource: @res3, status: 'curation', user: @user).process
            expect(@identifier.reload.latest_resource_with_public_metadata).to eql(@res2)
          end

          it 'finds embargoed published resource' do
            CurationService.new(resource: @res1, status: 'curation', user: @user).process
            CurationService.new(resource: @res1, status: 'published', user: @user).process
            CurationService.new(resource: @res1, status: 'curation', user: @user).process
            CurationService.new(resource: @res2, status: 'embargoed', user: @user).process
            CurationService.new(resource: @res3, status: 'curation', user: @user).process
            expect(@identifier.reload.latest_resource_with_public_metadata).to eql(@res2)
          end

          it 'finds no published resource' do
            CurationService.new(resource: @res1, status: 'curation', user: @user).process
            CurationService.new(resource: @res2, status: 'curation', user: @user).process
            CurationService.new(resource: @res3, status: 'to_be_published', user: @user).process
            expect(@identifier.reload.latest_resource_with_public_metadata).to eql(nil)
          end

          it 'disallows any access if latest state is withdrawn' do
            CurationService.new(resource: @res1, status: 'curation', user: @user).process
            CurationService.new(resource: @res1, status: 'published', user: @user).process
            CurationService.new(resource: @res2, status: 'curation', user: @user).process
            CurationService.new(resource: @res2, status: 'published', user: @user).process
            CurationService.new(resource: @res3, status: 'curation', user: @user).process
            CurationService.new(resource: @res3, status: 'withdrawn', user: @user).process
            expect(@identifier.reload.latest_resource_with_public_metadata).to eql(nil)
          end

        end

        describe '#latest_viewable_resource' do
          # the latest viewable resource depends on the user viewing and their ownership or role may allow them to view
          # published resources or not

          before(:each) do
            CurationService.new(status: 'curation', user: @user, resource: @res1).process
            CurationService.new(status: 'published', user: @user, resource: @res1).process
            CurationService.new(status: 'curation', user: @user, resource: @res2).process
            CurationService.new(status: 'published', user: @user, resource: @res2).process
            CurationService.new(status: 'curation', user: @user, resource: @res3).process
          end

          it 'returns the latest published for nil user' do
            expect(@identifier.latest_viewable_resource(user: nil)).to eql(@identifier.latest_resource_with_public_metadata)
          end

          it 'returns the latest published for non-owner and regular user' do
            user2 = create(:user)
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource_with_public_metadata)
          end

          it 'returns the latest non-published for the owner' do
            expect(@identifier.latest_viewable_resource(user: @user)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest non-published for a curator' do
            user2 = create(:user, role: 'curator')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest non-published for an admin from the same tenant as the owner' do
            user2 = create(:user, tenant_id: 'localhost')
            create(:role, user: user2, role: 'admin', role_object: user2.tenant)
            @res1.update(tenant_id: 'localhost')
            @res2.update(tenant_id: 'localhost')
            @res3.update(tenant_id: 'localhost')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest published for an admin from a different tenant as the owner' do
            user2 = create(:user, tenant_id: 'clownschool')
            create(:role, user: user2, role: 'admin', role_object: user2.tenant)
            @res1.update(tenant_id: 'localhost')
            @res2.update(tenant_id: 'localhost')
            @res3.update(tenant_id: 'localhost')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource_with_public_metadata)
          end

          it 'returns the latest non-published for an admin from journal' do
            user2 = create(:user, tenant_id: 'localhost')
            journal = create(:journal, title: 'Test Journal', issn: @fake_issn)
            create(:role, role_object: journal, user: user2, role: 'admin')
            user2.reload
            InternalDatum.create(identifier_id: @identifier.id, data_type: 'publicationISSN', value: @fake_issn)
            @identifier.reload
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource)
          end
        end

        describe '#latest_resource_with_public_download' do

          it 'finds the last download resource' do
            create(:data_file, resource: @res1, download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res1, user: @user)
            create(:curation_activity, :published, resource: @res1, user: @user)
            create(:data_file, resource: @res2, file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res2, user: @user)
            create(:curation_activity, :published, resource: @res2, user: @user)
            create(:data_file, resource: @res3, file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res3, user: @user)
            expect(@identifier.latest_resource_with_public_download).to eql(@res1)
          end

          it 'finds published resource' do
            create(:data_file, resource: @res1, download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res1, user: @user)
            create(:curation_activity, :published, resource: @res1, user: @user)
            create(:data_file, resource: @res2, file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res2, user: @user)
            create(:curation_activity, :embargoed, resource: @res2, user: @user)
            create(:data_file, resource: @res3, file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
            create(:curation_activity, :curation, resource: @res3, user: @user)
            expect(@identifier.latest_resource_with_public_download).to eql(@res1)
          end

          it 'finds no published resource' do
            create(:curation_activity, :curation, resource: @res1, user: @user)
            create(:curation_activity, :curation, resource: @res2, user: @user)
            create(:curation_activity, :curation, resource: @res3, user: @user)
            expect(@identifier.latest_resource_with_public_metadata).to eql(nil)
          end

          it 'disallows any access if latest state is withdrawn' do
            create(:curation_activity, :curation, resource: @res1, user: @user)
            create(:curation_activity, :published, resource: @res1, user: @user)
            create(:curation_activity, :curation, resource: @res2, user: @user)
            create(:curation_activity, :published, resource: @res2, user: @user)
            create(:curation_activity, :withdrawn, resource: @res3, user: @user)
            expect(@identifier.reload.latest_resource_with_public_metadata).to eql(nil)
          end

        end

      end

      describe '#update_search_words!' do
        before(:each) do
          @identifier2 = Identifier.create(identifier_type: 'DOI', identifier: '10.123/450')
          u = create(:user)
          @res5 = Resource.create(identifier_id: @identifier2.id, title: 'Frolicks with the seahorses', current_editor_id: u.id)
          Author.create(author_first_name: 'Joanna', author_last_name: 'Jones', author_orcid: '33-22-4838-3322', resource: @res5)
          Author.create(author_first_name: 'Marcus', author_last_name: 'Lee', author_orcid: '88-11-1138-2233', resource: @res5)
          @identifier2.save!
        end

        it 'has concatenated all the search fields' do
          @identifier2.reload
          @identifier2.update_search_words!
          @identifier2.reload
          expect(@identifier2.search_words.strip).to eq('doi:10.123/450 Frolicks with the seahorses ' \
                                                        'Joanna Jones  33-22-4838-3322 Marcus Lee  88-11-1138-2233')
        end
      end
    end

    describe '#user_must_pay?' do
      before(:each) do
        allow(@identifier).to receive(:institution_will_pay?).and_return(false)
        allow(@identifier).to receive(:funder_will_pay?).and_return(false)
      end

      it 'returns true if no one else will pay' do
        expect(@identifier.user_must_pay?).to eq(true)
      end

      it 'returns false if waiver is applied on an old_payment_system dataset' do
        @identifier.update(payment_type: 'waiver')
        expect(@identifier.user_must_pay?).to eq(true)

        @identifier.update(old_payment_system: true, payment_type: 'waiver')
        expect(@identifier.user_must_pay?).to eq(false)
      end

      it 'returns false if journal will pay' do
        journal = create(:journal, issn: @fake_issn)
        create(:payment_configuration, partner: journal, payment_plan: 'SUBSCRIPTION')
        journal.reload
        expect(@identifier.user_must_pay?).to eq(false)
      end

      it 'returns false if institution will pay' do
        allow(@identifier).to receive(:institution_will_pay?).and_return(true)
        expect(@identifier.user_must_pay?).to eq(false)
      end
    end

    describe '#record_payment' do
      it 'does nothing when a payment has already been recorded' do
        @identifier.payment_type = 'bogus_payment_type'
        expect(@identifier.record_payment).to eq(nil)
        expect(@identifier.payment_type).to eq('bogus_payment_type')
      end

      it 'records a journal payment' do
        journal = create(:journal, issn: @fake_issn)
        create(:payment_configuration, partner: journal, payment_plan: 'SUBSCRIPTION')
        @identifier.record_payment
        expect(@identifier.payment_type).to match(/journal/)
      end

      it 'replaces a journal payment when the associated journal has changed' do
        journal = create(:journal, issn: @fake_issn)
        create(:payment_configuration, partner: journal, payment_plan: 'SUBSCRIPTION')
        @identifier.record_payment
        expect(@identifier.payment_type).to match(/journal/)
        @pub.update(publication_issn: '0000-0000')
        @identifier.reload
        @identifier.record_payment
        expect(@identifier.payment_type).to match(/unknown/)
      end

      it 'records an institution payment' do
        allow(@identifier).to receive(:institution_will_pay?).and_return(true)
        @identifier.record_payment
        expect(@identifier.payment_type).to eq('institution')
      end

      it 'records a funder-based payment' do
        allow_any_instance_of(StashEngine::Resource).to receive(:contributors).and_return(
          [
            OpenStruct.new(payment_exempted?: false, contributor_name: 'Johann Strauss University', award_number: 'Latke153'),
            OpenStruct.new(payment_exempted?: true, contributor_name: 'Zorgast Industries', award_number: 'ZI0027')
          ]
        )
        @identifier.record_payment
        expect(@identifier.payment_type).to eql('funder')
        expect(@identifier.payment_id).to include('Zorgast Industries')
        expect(@identifier.payment_id).to include('award:')
        expect(@identifier.payment_id).to include('ZI0027')
      end
    end

    describe '#publication_issn' do
      it 'gets publication_issn through convenience method' do
        expect(@identifier.publication_issn).to eql(@fake_issn)
      end
    end

    describe '#manuscript_number' do
      it 'gets manuscript_number through convenience method' do
        expect(@identifier.manuscript_number).to eql(@fake_manuscript_number)
      end
    end

    describe '#has_accepted_manuscript?' do
      it 'is false when no matching manuscript exists' do
        expect(@identifier.has_accepted_manuscript?).to be(false)
      end

      it 'is true when matching manuscript is accepted' do
        create(:manuscript, manuscript_number: @fake_manuscript_number, status: 'accepted')
        expect(@identifier.has_accepted_manuscript?).to be(true)
      end

      it 'is false when matching manuscript is submitted' do
        create(:manuscript, manuscript_number: @fake_manuscript_number, status: 'submitted')
        expect(@identifier.has_accepted_manuscript?).to be(false)
      end
    end

    describe '#publication_article_doi' do
      it 'gets publication_article_doi through convenience method' do
        @fake_article_doi = 'http://doi.org/10.1234/bogus-doi'
        allow_any_instance_of(Resource).to receive(:related_identifiers).and_return([OpenStruct.new(
          related_identifier: @fake_article_doi, related_identifier_type: 'doi', relation_type: 'iscitedby', work_type: 'primary_article'
        )])
        expect(@identifier.publication_article_doi).to eql(@fake_article_doi)
      end
    end

    describe '#journal' do
      it 'retrieves the associated journal' do
        @bogus_title = 'Some Bogus Title'
        create(:journal, issn: @fake_issn, title: @bogus_title)
        expect(@identifier.journal.title).to eq(@bogus_title)
      end

      it 'allows review when there is no journal' do
        expect(@identifier.allow_review?).to be(true)
      end

      it 'disallows review if already published' do
        @identifier.pub_state = 'published'
        expect(@identifier.allow_review?).to be(false)
      end

      it 'allows review when the curation status is review, regardless of journal settings' do
        create(:journal, issn: @fake_issn, allow_review_workflow: false)
        allow_any_instance_of(Resource).to receive(:current_curation_status).and_return('peer_review')
        expect(@identifier.allow_review?).to be(true)
      end
    end

    describe '#institution_will_pay?' do
      it 'does not make user pay when institution pays' do
        @user.update(tenant_id: 'ucop')
        ident = create(:identifier)
        create(:resource, identifier_id: ident.id, user: @user)
        ident = Identifier.find(ident.id) # need to reload ident from the DB to update latest_resource
        expect(ident.institution_will_pay?).to eq(true)
      end

      it "doesn't make institution pay if there is no DPC coverage" do
        @user.update(tenant_id: 'dryad')
        ident = create(:identifier)
        create(:resource, identifier_id: ident.id, user: @user)
        ident = Identifier.find(ident.id) # need to reload ident from the DB to update latest_resource
        expect(ident.institution_will_pay?).to eq(false)
      end

      describe '"author_match" strategy' do
        before(:each) do
          @tenant = create(:tenant_match)
          @user.update(tenant_id: 'match_tenant')
          @resource = create(:resource, user: @user)
        end

        it 'says institution pays when an author ror matches an institution ror' do
          affil = @resource.authors.first.affiliations.first
          affil.update(ror_id: @tenant.ror_ids.first)
          @resource.reload
          expect(@resource.identifier.institution_will_pay?).to eq(true)
        end

        it "doesn't make institution pay if the authors are not from the institution" do
          expect(@resource.identifier.institution_will_pay?).to eq(false)
        end
      end
    end

    describe '#funder_will_pay?' do
      it 'does not make user pay when funder pays' do
        allow_any_instance_of(StashEngine::Resource).to receive(:contributors)
          .and_return([OpenStruct.new(payment_exempted?: false), OpenStruct.new(payment_exempted?: true)])
        expect(@identifier.funder_will_pay?).to be_truthy
      end

      it 'makes the user pay when funder will not' do
        allow_any_instance_of(StashEngine::Resource).to receive(:contributors)
          .and_return([OpenStruct.new(payment_exempted?: false), OpenStruct.new(payment_exempted?: false)])
        expect(@identifier.funder_will_pay?).to be_falsey
      end
    end

    describe '#funder_payment_info' do
      it 'returns payment information if funder is paying' do
        allow_any_instance_of(StashEngine::Resource).to receive(:contributors).and_return(
          [
            OpenStruct.new(payment_exempted?: false, contributor_name: 'Johann Strauss University', award_number: 'Latke153'),
            OpenStruct.new(payment_exempted?: true,  contributor_name: 'Zorgast Industries', award_number: 'ZI0027')
          ]
        )
        expect(@identifier.funder_payment_info).to eql(
          OpenStruct.new(payment_exempted?: true, contributor_name: 'Zorgast Industries', award_number: 'ZI0027')
        )
      end

      it 'returns nil if no funder payment' do
        allow_any_instance_of(StashEngine::Resource).to receive(:contributors).and_return(
          [
            OpenStruct.new(payment_exempted?: false, contributor_name: 'Johann Strauss University', award_number: 'Latke153'),
            OpenStruct.new(payment_exempted?: false, contributor_name: 'Zorgast Industries', award_number: 'ZI0027')
          ]
        )
        expect(@identifier.funder_payment_info).to eql(nil)
      end
    end

    describe '#submitter_affiliation' do
      it 'returns the current version\'s submitter\'s affiliation' do
        expect(@identifier.submitter_affiliation).to eql(@identifier.latest_resource&.owner_author&.affiliation)
      end
    end

    describe '#calculated_pub_state' do

      it 'detects withdrawn state' do
        res = @identifier.resources.last
        CurationService.new(status: 'withdrawn', user: @user, resource: res).process
        expect(@identifier.calculated_pub_state).to eq('withdrawn')
      end

      it 'detects last published state' do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[1]).process
        expect(@identifier.calculated_pub_state).to eq('published')
      end

      it 'detects last embargoed state' do
        resources = @identifier.resources
        CurationService.new(status: 'embargoed', user: @user, resource: resources[0]).process
        expect(@identifier.calculated_pub_state).to eq('embargoed')
      end

      it 'detects unpublished' do
        expect(@identifier.calculated_pub_state).to eq('unpublished')
      end

      it 'handles no curation activities' do
        @identifier.resources.each do |res|
          res.curation_activities.destroy_all
        end
        expect(@identifier.calculated_pub_state).to eq('unpublished')
      end

      it 'handles no resources' do
        @identifier.resources.destroy_all
        expect(@identifier.calculated_pub_state).to eq('unpublished')
      end

    end

    # because it overrides the ActiveRecord one
    describe '#pub_state' do

      before(:each) { neuter_curation_callbacks! }

      it "retrieves a pub state, even when one isn't set" do
        expect(@identifier.pub_state).to eq(@identifier.calculated_pub_state)
      end

      it 'retrieves a pub state saved to the database' do
        @identifier.update(pub_state: 'embargoed')
        @identifier.reload
        expect(@identifier.pub_state).to eq('embargoed')
      end

      describe '#embargoed_until_article?' do
        it 'defaults to not embargoed_until_article' do
          expect(@identifier.embargoed_until_article_appears?).to be(false)
        end

        it 'detects embargoed_until_article' do
          CurationService.new(resource: @res3, status: 'embargoed', user: @user,
                              note: 'Adding 1-year blackout period due to journal settings.').process
          expect(@identifier.reload.embargoed_until_article_appears?).to be(true)
        end
      end
    end

    describe '#fill_resource_view_flags' do
      before(:each) { neuter_curation_callbacks! }

      it 'sets nothing when no published states' do
        @identifier.fill_resource_view_flags
        @identifier.reload
        @identifier.resources.each do |res|
          expect(res.meta_view).to eq(false)
          expect(res.file_view).to eq(false)
        end
      end

      it 'sets the file view when published and changed' do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[1]).process
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process
        @identifier.fill_resource_view_flags
        @identifier.reload
        expect(@identifier.resources[1].meta_view).to be(true)
        expect(@identifier.resources[1].file_view).to be(false) # no files added yet
        expect(@identifier.resources[2].meta_view).to be(true)
        expect(@identifier.resources[2].file_view).to be(true) # files added this version
      end

      it 'sets the file when published and changed 2' do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[0]).process
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        resources[0].data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)

        @identifier.fill_resource_view_flags

        @identifier.reload

        expect(@identifier.resources[0].meta_view).to be(true) # yes published
        expect(@identifier.resources[0].file_view).to be(true) # yes, new file added
        expect(@identifier.resources[1].meta_view).to be(false) # no, not published
        expect(@identifier.resources[1].file_view).to be(false) # no new files added or deleted, and not published
        expect(@identifier.resources[2].meta_view).to be(true)  # yes, published
        expect(@identifier.resources[2].file_view).to be(true) # files added this version
      end

      it "doesn't set the file_view when published, but files are not changed between published versions" do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[0]).process
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        resources[0].data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
        resources[1].data_files << DataFile.create(file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
        resources[2].data_files.destroy_all
        resources[2].data_files << DataFile.create(file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)

        @identifier.fill_resource_view_flags

        @identifier.reload

        expect(@identifier.resources[0].meta_view).to be(true) # yes published
        expect(@identifier.resources[0].file_view).to be(true) # yes, new file added
        expect(@identifier.resources[1].meta_view).to be(false) # no, not published
        expect(@identifier.resources[1].file_view).to be(false) # no new files added or deleted, and not published
        expect(@identifier.resources[2].meta_view).to be(true)  # yes, published
        expect(@identifier.resources[2].file_view).to be(false) # files added this version
      end

      it 'sets the file_view when published, but files are deleted' do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[0]).process
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        resources[0].data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
        resources[1].data_files << DataFile.create(file_state: 'deleted', download_filename: 'fun.cat', upload_file_size: 666)
        resources[2].data_files.destroy_all
        resources[2].data_files << DataFile.create(file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)

        @identifier.fill_resource_view_flags

        @identifier.reload

        expect(@identifier.resources[0].meta_view).to be(true) # yes published
        expect(@identifier.resources[0].file_view).to be(true) # yes, new file added
        expect(@identifier.resources[1].meta_view).to be(false) # no, not published
        expect(@identifier.resources[1].file_view).to be(false) # no new files added or deleted, and not published
        expect(@identifier.resources[2].meta_view).to be(true)  # yes, published
        expect(@identifier.resources[2].file_view).to be(true) # files added this version
      end

      it 'sets the file_view when published, but files are mistaknely removed by user' do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[0]).process
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        resources[0].data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
        resources[1].data_files << DataFile.create(file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
        resources[2].data_files.destroy_all
        resources[2].data_files << DataFile.create(file_state: 'deleted', download_filename: 'fun.cat', upload_file_size: 666)

        @identifier.fill_resource_view_flags
        @identifier.reload

        expect(@identifier.resources[0].meta_view).to be(true) # yes published
        expect(@identifier.resources[0].file_view).to be(true) # yes, new file added
        expect(@identifier.resources[1].meta_view).to be(false) # no, not published
        expect(@identifier.resources[1].file_view).to be(false) # no new files added or deleted, and not published
        expect(@identifier.resources[2].meta_view).to be(true)  # yes, published
        expect(@identifier.resources[2].file_view).to be(false) # all files deleted from this version, so don't show it as a version
      end
    end

    # Disabling the 'borked' tests because they were breaking, and I think we should remove this functionality anyway.
    describe '#borked_file_history' do
      before(:each) { neuter_curation_callbacks! }

      xit "detects we've disassociated version history with negative resource_ids" do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        # this is how we bork things for curators to get the pretty views, I hope this doesn't last long
        resources[0].update(identifier_id: -resources[0].identifier_id)
        resources[1].update(identifier_id: -resources[1].identifier_id)

        puts "RES are #{resources} -- #{resources[1]} -- #{resources[0]}"

        expect(@identifier.borked_file_history?).to eq(true)
      end

      xit "detects we've disassociated version history because nothing was ever changed (created/deleted), just copied from previous versions" do
        resources = @identifier.resources
        CurationService.new(status: 'published', user: @user, resource: resources[2]).process

        resources[2].data_files << DataFile.create(file_state: 'copied', download_filename: 'fun.cat', upload_file_size: 666)
        resources[2].data_files.each { |fu| fu.update(file_state: 'copied') } # make them all copied, so invalid file history
        @identifier.reload

        expect(@identifier.borked_file_history?).to eq(true)
      end
    end

    describe :with_visibility do
      before(:each) do
        Identifier.destroy_all
        @user = create(:user, first_name: 'Lisa', last_name: 'Muckenhaupt', email: 'lmuckenhaupt@datadryad.org', tenant_id: 'ucop')
        @user2 = create(:user, first_name: 'Gargola', last_name: 'Jones', email: 'luckin@datadryad.org', tenant_id: 'ucop')
        create(:role, user: @user2, role: 'admin', role_object: @user2.tenant)
        @user3 = create(:user, first_name: 'Merga', last_name: 'Flav', email: 'flavin@datadryad.org', tenant_id: 'ucb', role: 'curator')

        @identifiers = [create(:identifier, identifier: '10.1072/FK2000'),
                        create(:identifier, identifier: '10.1072/FK2001'),
                        create(:identifier, identifier: '10.1072/FK2002'),
                        create(:identifier, identifier: '10.1072/FK2003'),
                        create(:identifier, identifier: '10.1072/FK2004'),
                        create(:identifier, identifier: '10.1072/FK2005'),
                        create(:identifier, identifier: '10.1072/FK2006'),
                        create(:identifier, identifier: '10.1072/FK2007')]
        Timecop.travel(Time.now.utc - 1.hour)
        @resources = [
          create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[0].id),
          create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[1].id),
          create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
          create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[3].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[4].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[5].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[6].id),
          create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[7].id)
        ]
        Timecop.return
        @resources.insert(1, create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[0].id))
        @resources.insert(4, create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id))

        @curation_activities = [[create(:curation_activity, :in_progress, resource: @resources[0]),
                                 create(:curation_activity, :curation, resource: @resources[0]),
                                 create(:curation_activity, :published, resource: @resources[0])]]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[1]),
                                 create(:curation_activity, :curation, resource: @resources[1]),
                                 create(:curation_activity, :embargoed, resource: @resources[1])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[2]),
                                 create(:curation_activity, :curation, resource: @resources[2])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[3]),
                                 create(:curation_activity, :curation, resource: @resources[3]),
                                 create(:curation_activity, :action_required, resource: @resources[3])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[4]),
                                 create(:curation_activity, :curation, resource: @resources[4]),
                                 create(:curation_activity, :published, resource: @resources[4])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[5]),
                                 create(:curation_activity, :curation, resource: @resources[5]),
                                 create(:curation_activity, :embargoed, resource: @resources[5])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[6]),
                                 create(:curation_activity, :curation, resource: @resources[6]),
                                 create(:curation_activity, :withdrawn, resource: @resources[6])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[7])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[8]),
                                 create(:curation_activity, :curation, resource: @resources[8]),
                                 create(:curation_activity, :published, resource: @resources[8])]

        @curation_activities << [create(:curation_activity, :in_progress, resource: @resources[9]),
                                 create(:curation_activity, :curation, resource: @resources[9]),
                                 create(:curation_activity, :embargoed, resource: @resources[9])]

        # this does DISTINCT and joins to resources and latest curation statuses
        # 5 identifers have been published
      end

      it 'lists publicly viewable in one query' do
        public_identifiers = Identifier.with_visibility(states: %w[published embargoed])
        expect(public_identifiers.count).to eq(5)
        expect(public_identifiers.map(&:id)).to include(@identifiers[7].id)
        expect(public_identifiers.map(&:id)).not_to include(@identifiers[5].id)
      end

      it 'lists publicly viewable and private in my tenant for admins' do
        identifiers = Identifier.with_visibility(states: %w[published embargoed], user_id: nil, tenant_id: 'ucop')
        expect(identifiers.count).to eq(6)
        expect(identifiers.map(&:id)).to include(@identifiers[1].id)
      end

      it 'lists publicly viewable and my own datasets for a user' do
        identifiers = Identifier.with_visibility(states: %w[published embargoed], user_id: @user.id)
        expect(identifiers.count).to eq(6)
        expect(identifiers.map(&:id)).to include(@identifiers[1].id)
      end

      it 'only picks up on a final resource state for each dataset' do
        identifiers = Identifier.with_visibility(states: 'curation')
        expect(identifiers.count).to eq(1)
        expect(identifiers.map(&:id)).to include(@identifiers[1].id)
      end

      it 'user_viewable for a regular user' do
        identifiers = Pundit.policy_scope!(@user, Identifier)
        expect(identifiers.count).to eq(6) # 5 public plus mine in curation
        expect(identifiers.map(&:id)).to include(@identifiers[1].id) # this is my private one
      end

      it 'user_viewable for an admin' do
        identifiers = Pundit.policy_scope!(@user2, Identifier)
        expect(identifiers.count).to eq(6)
        expect(identifiers.map(&:id)).to include(@identifiers[1].id) # this is some ucop joe blow private one
      end

      it 'user_viewable for a curator, they love it all' do
        identifiers = Pundit.policy_scope!(@user3, Identifier)
        expect(identifiers.count).to eq(@identifiers.length)
      end

    end

    describe :cited_by do
      before(:each) do
        neuter_curation_callbacks!
        user = create(:user, tenant_id: 'dryad')
        @identifier2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/789')
        @identifier3 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/000')
        # Add a resource and make it 'published'
        [@identifier, @identifier2, @identifier3].each do |identifier|
          resource = create(:resource, user: user, tenant_id: user.tenant_id, identifier_id: identifier.id, skip_datacite_update: true)
          create(:curation_activity, :in_progress, resource: resource)
          create(:curation_activity, :curation, resource: resource)
          create(:curation_activity, :published, resource: resource)
        end
      end

      it '#cited_by_pubmed should only return identifiers that have `pubmedID` internal datum' do
        InternalDatum.create(identifier_id: @identifier.id, data_type: 'pubmedID', value: 'ABCD')
        InternalDatum.create(identifier_id: @identifier2.id, data_type: 'pubmedID', value: '1234')
        InternalDatum.create(identifier_id: @identifier3.id, data_type: 'publicationName', value: 'TESTER')

        expect(Identifier.cited_by_pubmed.length).to eql(2)
      end

      it '#cited_by_external_site should only return identifiers that have the specified site in external references' do
        ExternalReference.create(identifier_id: @identifier.id, source: 'nuccore', value: 'ABCD')
        ExternalReference.create(identifier_id: @identifier2.id, source: 'nuccore', value: '1234')
        ExternalReference.create(identifier_id: @identifier3.id, source: 'bioproject', value: 'TESTER')

        expect(Identifier.cited_by_external_site('nuccore').length).to eql(2)
      end
    end

    describe '#has_zenodo_software' do
      before(:each) do
        @software_file = SoftwareFile.create(download_filename: 'test', file_state: 'created')
      end

      it 'correctly detects current zenodo software' do
        @res3.software_files << @software_file
        expect(@identifier.has_zenodo_software?).to eq(true)
      end

      it 'correctly detects former zenodo software' do
        @res1.software_files << @software_file
        expect(@identifier.has_zenodo_software?).to eq(true)
      end

      it 'correctly detects no zenodo software' do
        expect(@identifier.has_zenodo_software?).to eq(false)
      end
    end

    describe '#has_zenodo_supp' do
      before(:each) do
        @supp_file = SuppFile.create(download_filename: 'test', file_state: 'created')
      end

      it 'correctly detects current zenodo supplemental' do
        @res3.supp_files << @supp_file
        expect(@identifier.has_zenodo_supp?).to eq(true)
      end

      it 'correctly detects former zenodo supplemental' do
        @res1.supp_files << @supp_file
        expect(@identifier.has_zenodo_supp?).to eq(true)
      end

      it 'correctly detects no zenodo supplemental' do
        expect(@identifier.has_zenodo_supp?).to eq(false)
      end
    end

    it_should_behave_like 'soft delete record', :identifier
  end
end
