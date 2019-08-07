require 'db_spec_helper'
require 'webmock/rspec'
require_relative '../../../../spec_helpers/factory_helper'
require 'byebug'

module StashEngine

  describe Identifier do
    attr_reader :identifier
    attr_reader :usage1
    attr_reader :usage2
    attr_reader :res1
    attr_reader :res2
    attr_reader :res3

    before(:each) do
      @user = User.new
      @identifier = Identifier.create(identifier_type: 'DOI', identifier: '10.123/456')
      @res1 = Resource.create(identifier_id: @identifier.id, user: @user)
      @res2 = Resource.create(identifier_id: @identifier.id, user: @user)
      @res3 = Resource.create(identifier_id: @identifier.id, user: @user)

      @created_files = Array.new(3) do |i|
        FileUpload.create(
          resource: @res3,
          file_state: 'created',
          upload_file_name: "created#{i}.bin",
          upload_file_size: i * 3
        )
      end

      @fake_issn = 'bogus-issn-value'
      int_datum = InternalDatum.new(identifier_id: @identifier.id, data_type: 'publicationISSN', value: @fake_issn)
      int_datum.save!
      @identifier.reload

      WebMock.disable_net_connect!
    end

    after(:each) do
      WebMock.allow_net_connect!
    end

    describe '#to_s' do
      it 'returns something useful' do
        expect(identifier.to_s).to eq('doi:10.123/456')
      end
    end

    describe 'versioning' do
      before(:each) do
        res1.current_state = 'submitted'
        Version.create(resource_id: res1.id, version: 1)

        res2.current_state = 'submitted'
        Version.create(resource_id: res2.id, version: 2)

        res3.current_state = 'in_progress'
        Version.create(resource_id: res3.id, version: 3)
      end

      describe '#first_submitted_resource' do
        it 'returns the first submitted version' do
          lsv = identifier.first_submitted_resource
          expect(lsv.id).to eq(res1.id)
        end
      end

      describe '#last_submitted_resource' do
        it 'returns the last submitted version' do
          lsv = identifier.last_submitted_resource
          expect(lsv.id).to eq(res2.id)
        end
      end

      describe '#latest_resource' do
        it 'returns the latest resource' do
          expect(identifier.latest_resource_id).to eq(res3.id)
        end
      end

      describe '#in_progress_resource' do
        it 'returns the in-progress version' do
          ipv = identifier.in_progress_resource
          expect(ipv.id).to eq(res3.id)
        end
      end

      describe '#in_progress?' do
        it 'returns true if an in-progress version exists' do
          expect(identifier.in_progress?).to eq(true)
        end
        it 'returns false if no in-progress version exists' do
          res3.current_state = 'submitted'
          expect(identifier.in_progress?).to eq(false)
        end
      end

      describe '#processing_resource' do
        before(:each) do
          res2.current_state = 'processing'
        end

        it 'returns the "processing" version' do
          pv = identifier.processing_resource
          expect(pv.id).to eq(res2.id)
        end
      end

      describe '#processing?' do
        it 'returns false if no "processing" version exists' do
          expect(identifier.processing?).to eq(false)
        end

        it 'returns true if a "processing" version exists' do
          res2.current_state = 'processing'
          expect(identifier.processing?).to eq(true)
        end
      end

      describe '#error?' do
        it 'returns false if no "error" version exists' do
          expect(identifier.error?).to eq(false)
        end

        it 'returns true if a "error" version exists' do
          res2.current_state = 'error'
          expect(identifier.error?).to eq(true)
        end
      end

      # TODO: in progress is just the in-progress state itself of the group of in_progress states.  We need to fix our terminology.
      describe '#in_progress_only?' do
        it 'returns false if no "in_progress_only" version exists' do
          res3.current_state = 'submitted'
          expect(identifier.in_progress_only?).to eq(false)
        end

        it 'returns true if a "in_progress_only" version exists' do
          res2.current_state = 'error'
          expect(identifier.in_progress_only?).to eq(true)
        end
      end

      describe '#resources_with_file_changes' do
        before(:each) do
          FileUpload.create(resource_id: res1.id, upload_file_name: 'cat', file_state: 'created')
          FileUpload.create(resource_id: res2.id, upload_file_name: 'cat', file_state: 'copied')
          FileUpload.create(resource_id: res3.id, upload_file_name: 'cat', file_state: 'created')
        end

        it 'returns the version that changed' do
          resources = identifier.resources_with_file_changes
          expect(resources.first.id).to eq(res1.id)
          expect(resources.count).to eq(2)
        end
      end

      describe 'curation activity setup' do
        before(:each) do
          allow_any_instance_of(CurationActivity).to receive(:update_solr).and_return(true)
          allow_any_instance_of(CurationActivity).to receive(:submit_to_stripe).and_return(true)
          allow_any_instance_of(CurationActivity).to receive(:submit_to_datacite).and_return(true)
        end

        describe '#latest_resource_with_public_metadata' do

          it 'finds the last published resource' do
            @res1.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res1.curation_activities << CurationActivity.create(status: 'published', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'published', user: @user)
            @res3.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            expect(@identifier.latest_resource_with_public_metadata).to eql(@res2)
          end

          it 'finds embargoed published resource' do
            @res1.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res1.curation_activities << CurationActivity.create(status: 'published', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'embargoed', user: @user)
            @res3.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            expect(@identifier.latest_resource_with_public_metadata).to eql(@res2)
          end

          it 'finds no published resource' do
            @res1.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res3.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            expect(@identifier.latest_resource_with_public_metadata).to eql(nil)
          end

        end

        describe '#latest_viewable_resource' do
          # the latest viewable resource depends on the user viewing and their ownership or role may allow them to view
          # published resources or not

          before(:each) do
            @res1.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res1.curation_activities << CurationActivity.create(status: 'published', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'curation', user: @user)
            @res2.curation_activities << CurationActivity.create(status: 'published', user: @user)
            @res3.curation_activities << CurationActivity.create(status: 'curation', user: @user)
          end

          it 'returns the latest published for nil user' do
            expect(@identifier.latest_viewable_resource(user: nil)).to eql(@identifier.latest_resource_with_public_metadata)
          end

          it 'returns the latest published for non-owner and regular user' do
            user2 = User.new
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource_with_public_metadata)
          end

          it 'returns the latest non-published for the owner' do
            expect(@identifier.latest_viewable_resource(user: @user)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest non-published for a superuser' do
            user2 = User.new(role: 'superuser')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest non-published for an admin from the same tenant as the owner' do
            user2 = User.new(role: 'admin', tenant_id: 'localhost')
            @res1.update(tenant_id: 'localhost')
            @res2.update(tenant_id: 'localhost')
            @res3.update(tenant_id: 'localhost')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource)
          end

          it 'returns the latest published for an admin from a different tenant as the owner' do
            user2 = User.new(role: 'admin', tenant_id: 'clownschool')
            @res1.update(tenant_id: 'localhost')
            @res2.update(tenant_id: 'localhost')
            @res3.update(tenant_id: 'localhost')
            expect(@identifier.latest_viewable_resource(user: user2)).to eql(@identifier.latest_resource_with_public_metadata)
          end
        end
      end

      describe '#update_search_words!' do
        before(:each) do
          @identifier2 = Identifier.create(identifier_type: 'DOI', identifier: '10.123/450')
          @res5 = Resource.create(identifier_id: @identifier2.id, title: 'Frolicks with the seahorses')
          @identifier2.save!
          Author.create(author_first_name: 'Joanna', author_last_name: 'Jones', author_orcid: '33-22-4838-3322', resource_id: @res5.id)
          Author.create(author_first_name: 'Marcus', author_last_name: 'Lee', author_orcid: '88-11-1138-2233', resource_id: @res5.id)
        end

        it 'has concatenated all the search fields' do
          @identifier2.reload
          @identifier2.update_search_words!
          expect(@identifier2.search_words.strip).to eq('doi:10.123/450 Frolicks with the seahorses ' \
            'Joanna Jones  33-22-4838-3322 Marcus Lee  88-11-1138-2233')
        end
      end
    end

    describe '#user_must_pay?' do
      before(:each) do
        allow(@identifier).to receive(:'journal_will_pay?').and_return(false)
        allow(@identifier).to receive(:'institution_will_pay?').and_return(false)
      end

      it 'returns true if no one else will pay' do
        expect(@identifier.user_must_pay?).to eq(true)
      end

      it 'returns false if journal will pay' do
        allow(@identifier).to receive(:'journal_will_pay?').and_return(true)
        expect(@identifier.user_must_pay?).to eq(false)
      end

      it 'returns false if institution will pay' do
        allow(@identifier).to receive(:'institution_will_pay?').and_return(true)
        expect(@identifier.user_must_pay?).to eq(false)
      end
    end

    describe '#publication_data' do
      it 'reads the value correctly from json body' do
        stub_request(:any, %r{/journals/#{@fake_issn}})
          .to_return(body: { blah: 'meow' }.to_json,
                     status: 200,
                     headers: { 'Content-Type' => 'application/json' })
        expect(@identifier.publication_data('blah')).to eql('meow')
      end
    end

    describe '#publication_issn' do
      it 'gets publication_issn through convenience method' do
        expect(@identifier.publication_issn).to eql(@fake_issn)
      end
    end

    describe '#publication_name' do
      it 'retrieves the publication_name' do
        @fake_journal_name = 'Fake Journal'
        stub_request(:any, %r{/journals/#{@fake_issn}})
          .to_return(body: '{"fullName":"' + @fake_journal_name + '",
                             "issn":"' + @fake_issn + '",
                             "website":"http://onlinelibrary.wiley.com/journal/10.1111/(ISSN)1365-294X",
                             "description":"Molecular Ecology publishes papers that utilize molecular genetic techniques..."}',
                     status: 200,
                     headers: { 'Content-Type' => 'application/json' })
        expect(identifier.publication_name).to eq(@fake_journal_name)
      end
    end

    describe '#journal_customer_id' do
      it 'retrieves the journal Stripe customer ID' do
        @fake_journal_name = 'Fake Journal'
        @fake_customer_id = 'cust_abc123'
        stub_request(:any, %r{/journals/#{@fake_issn}})
          .to_return(body: '{"fullName":"' + @fake_journal_name + '",
                             "issn":"' + @fake_issn + '",
                             "website":"http://onlinelibrary.wiley.com/journal/10.1111/(ISSN)1365-294X",
                             "description":"Molecular Ecology publishes papers that utilize molecular genetic techniques...",
                             "stripeCustomerID":"' + @fake_customer_id + '"}',
                     status: 200,
                     headers: { 'Content-Type' => 'application/json' })
        expect(identifier.journal_customer_id).to eq(@fake_customer_id)
      end
    end

    describe '#journal_allows' do
      it 'allows review when there is no journal' do
        allow(@identifier).to receive('publication_name').and_return(nil)
        allow(@identifier).to receive('publication_data').and_return(false)
        expect(@identifier.allow_review?).to be(true)
      end

      it 'allows review when the journal allows review' do
        allow(@identifier).to receive('publication_name').and_return('fakename')
        allow(@identifier).to receive('publication_data').and_return(true)
        expect(@identifier.allow_review?).to be(true)
      end

      it 'disallows review when the journal disallows review' do
        allow(@identifier).to receive('publication_name').and_return('fakename')
        allow(@identifier).to receive('publication_data').and_return(false)
        expect(@identifier.allow_review?).to be(false)
      end

      it 'disallows blackout by default' do
        allow(@identifier).to receive('publication_data').and_return(nil)
        expect(@identifier.allow_blackout?).to be(false)
      end

      it 'allows blackout when the journal allows blackout' do
        allow(@identifier).to receive('publication_data').and_return(true)
        expect(@identifier.allow_blackout?).to be(true)
      end
    end

    describe '#journal_will_pay?' do
      it 'returns true when there is a PREPAID plan' do
        allow(@identifier).to receive('publication_data').and_return('PREPAID')
        expect(@identifier.journal_will_pay?).to be(true)
      end

      it 'returns true when there is a SUBSCRIPTION plan' do
        allow(@identifier).to receive('publication_data').and_return('SUBSCRIPTION')
        expect(@identifier.journal_will_pay?).to be(true)
      end

      it 'returns false when there is a no plan' do
        allow(@identifier).to receive('publication_data').and_return(nil)
        expect(@identifier.journal_will_pay?).to be(false)
      end

      it 'returns false when there is an unrecognized plan' do
        allow(@identifier).to receive('publication_data').and_return('BOGUS-PLAN')
        expect(@identifier.journal_will_pay?).to be(false)
      end
    end

    describe '#institution_will_pay?' do
      it 'does not make user pay when institution pays' do
        tenant = class_double(Tenant)
        allow(Tenant).to receive(:find).with('paying-institution').and_return(tenant)
        allow(Tenant).to receive(:covers_dpc).and_return(true)
        allow(tenant).to receive(:covers_dpc).and_return(true)
        ident = Identifier.create
        Resource.create(tenant_id: 'paying-institution', identifier_id: ident.id)
        ident = Identifier.find(ident.id) # need to reload ident from the DB to update latest_resource
        expect(ident.institution_will_pay?).to eq(true)
      end
    end

    describe '#submitter_affiliation' do
      it 'returns the current version\'s first author\'s affiliation' do
        expect(@identifier.submitter_affiliation).to eql(@identifier.latest_resource&.authors&.first&.affiliation)
      end
    end

    describe '#large_files?' do
      before(:each) do
        app = double(Rails::Application)
        allow(app).to receive(:payments).and_return(OpenStruct.new(large_file_size: 100))
        allow(StashEngine).to receive(:app).and_return(app)
      end

      it 'returns false when large files are not present' do
        expect(@identifier.large_files?).to eq(false)
      end

      it 'returns true when large files are present' do
        FileUpload.create(
          resource: @res3,
          file_state: 'created',
          upload_file_name: 'created.bin',
          upload_file_size: 10_000
        )
        expect(@identifier.large_files?).to eq(true)
      end

    end

    describe :with_visibility do
      before(:each) do
        Identifier.destroy_all
        @user = create(:user, first_name: 'Lisa', last_name: 'Muckenhaupt', email: 'lmuckenhaupt@ucop.edu', tenant_id: 'ucop', role: nil)
        @user2 = create(:user, first_name: 'Gargola', last_name: 'Jones', email: 'luckin@ucop.edu', tenant_id: 'ucop', role: 'admin')
        @user3 = create(:user, first_name: 'Merga', last_name: 'Flav', email: 'flavin@ucop.edu', tenant_id: 'ucb', role: 'superuser')

        @identifiers = [create(:identifier, identifier: '10.1072/FK2000'),
                        create(:identifier, identifier: '10.1072/FK2001'),
                        create(:identifier, identifier: '10.1072/FK2002'),
                        create(:identifier, identifier: '10.1072/FK2003'),
                        create(:identifier, identifier: '10.1072/FK2004'),
                        create(:identifier, identifier: '10.1072/FK2005'),
                        create(:identifier, identifier: '10.1072/FK2006'),
                        create(:identifier, identifier: '10.1072/FK2007')]

        @resources = [create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[0].id),
                      create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[0].id),
                      create(:resource, user_id: @user.id, tenant_id: @user.tenant_id, identifier_id: @identifiers[1].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[2].id),
                      create(:resource, user_id: @user2.id, tenant_id: @user2.tenant_id, identifier_id: @identifiers[3].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[4].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[5].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[6].id),
                      create(:resource, user_id: @user3.id, tenant_id: @user3.tenant_id, identifier_id: @identifiers[7].id)]

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
        identifiers = Identifier.user_viewable(user: @user)
        expect(identifiers.count).to eq(6) # 5 public plus mine in curation
        expect(identifiers.map(&:id)).to include(@identifiers[1].id) # this is my private one
      end

      it 'user_viewable for an admin' do
        identifiers = Identifier.user_viewable(user: @user2)
        expect(identifiers.count).to eq(6)
        expect(identifiers.map(&:id)).to include(@identifiers[1].id) # this is some ucop joe blow private one
      end

      it 'user_viewable for a superuser, they love it all' do
        identifiers = Identifier.user_viewable(user: @user3)
        expect(identifiers.count).to eq(@identifiers.length)
      end

    end

    describe :cited_by do
      before(:each) do
        user = User.new
        @identifier2 = Identifier.create(identifier_type: 'DOI', identifier: '10.123/789')
        @identifier3 = Identifier.create(identifier_type: 'DOI', identifier: '10.123/000')

        # Add a resource and make it 'published'
        [@identifier, @identifier2, @identifier3].each do |identifier|
          resource = create(:resource, user_id: user.id, tenant_id: user.tenant_id, identifier_id: identifier.id)
          create(:curation_activity_no_callbacks, resource: resource, status: 'in_progress')
          create(:curation_activity_no_callbacks, resource: resource, status: 'curation')
          create(:curation_activity_no_callbacks, resource: resource, status: 'published')
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

  end
end
