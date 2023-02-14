require 'byebug'

module StashEngine
  describe CurationActivity, type: :model do

    include Mocks::Datacite
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe
    include Mocks::CurationActivity

    before(:each) do
      mock_solr!
      mock_datacite!
      mock_salesforce!
      mock_stripe!

      @identifier = create(:identifier, identifier_type: 'DOI', identifier: '10.123/123')
      @resource = create(:resource, identifier_id: @identifier.id)
      # reload so that it picks up any associated models that are initialized
      # (e.g. CurationActivity and ResourceState)
      @resource.reload
      allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
    end

    context :new do
      it 'defaults status to :in_progress' do
        activity = CurationActivity.new(resource: @resource)
        expect(activity.status).to eql('in_progress')
      end

      it 'requires a resource' do
        activity = CurationActivity.new(resource: nil)
        expect(activity.valid?).to eql(false)
      end
    end

    context :latest do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'returns the most recent activity' do
        ca2 = create(:curation_activity, resource: @resource, status: 'peer_review', note: 'this is a test')
        expect(CurationActivity.latest(resource: @resource)).to eql(ca2)
      end
    end

    context :readable_status do
      before(:each) do
        @ca = create(:curation_activity, resource: @resource)
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
      end

      it 'class method allows conversion of status to humanized status' do
        expect(CurationActivity.readable_status('submitted')).to eql('Submitted')
      end

      it 'returns a readable version of :peer_review' do
        @ca.peer_review!
        expect(@ca.readable_status).to eql('Private for peer review')
      end

      it 'returns a readable version of :action_required' do
        @ca.action_required!
        expect(@ca.readable_status).to eql('Author Action Required')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize.split.map(&:capitalize).join(' '))
          end
        end
      end
    end

    context :callbacks do

      context :update_solr do

        # TODO: Fix this intermittently-failing test. Ticket #806.
        xit 'calls update_solr when published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).to receive(:update_solr)
          ca.save
        end

        # TODO: Fix this intermittently-failing test. Ticket #806.
        xit 'calls update_solr when embargoed' do
          @resource.update(publication_date: (Date.today + 1.day).to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:update_solr)
          ca.save
        end

        it 'does not call update_solr if not published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'action_required')
          expect(ca).not_to receive(:update_solr)
          ca.save
        end

      end

      context :process_payment do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_status_change_notices).and_return(true)
        end

        # TODO: Fix this intermittently-failing test. Ticket #806.
        xit 'calls submit_to_stripe when published' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        # TODO: Fix this intermittently-failing test. Ticket #806.
        xit 'calls submit_to_stripe when embargoed' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe if not ready_for_payment' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(false)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'submitted')
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe if skip_datacite' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          allow_any_instance_of(StashEngine::Resource).to receive(:skip_datacite_update).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

        # TODO: Fix this intermittently-failing test. Ticket #806.
        xit 'does not call submit_to_stripe when user is not responsible for payment' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          allow_any_instance_of(StashEngine::Identifier).to receive(:user_must_pay?).and_return(false)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:process_payment)
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

      end

      context :email_status_change_notices do

        before(:each) do
          allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:journal_published_notice).and_return(true)
        end

        StashEngine::CurationActivity.statuses.each do |status|

          if %w[published embargoed peer_review submitted withdrawn].include?(status)
            it "sends email when '#{status}'" do
              expect_any_instance_of(StashEngine::UserMailer).to receive(:status_change)
              ca = create(:curation_activity, resource: @resource, status: status)
              ca.save
            end
          else
            it "does not send email when '#{status}'" do
              expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
              ca = create(:curation_activity, resource_id: @resource.id, status: status)
              ca.save
            end
          end

        end
      end

      context :clean_placeholders do
        before(:each) do
          @user = create(:user)
          @resource.contributors = [] # erase the default funder
        end

        it 'does nothing when there are no funders' do
          @resource.update(publication_date: Date.today.to_s)
          ca = StashEngine::CurationActivity.create(resource_id: @resource.id, status: 'published', user: @user)
          ca.save
          @resource.reload
          expect(@resource.contributors).to be_blank
        end

        it 'does nothing when there is a single non-placeholder funder' do
          funder = create(:contributor)
          @resource.contributors << funder
          @resource.update(publication_date: Date.today.to_s)
          ca = StashEngine::CurationActivity.create(resource_id: @resource.id, status: 'published', user: @user)
          ca.save
          @resource.reload
          expect(@resource.contributors).to be_present
          expect(@resource.contributors.first.contributor_name).to eq(funder.contributor_name)
        end

        it 'removes a placeholder funder' do
          @resource.contributors << StashDatacite::Contributor.new(contributor_name: 'N/A', contributor_type: 'funder', name_identifier_id: '0')
          @resource.update(publication_date: Date.today.to_s)
          ca = StashEngine::CurationActivity.create(resource_id: @resource.id, status: 'published', user: @user)
          ca.save
          @resource.reload
          expect(@resource.contributors).to be_blank
        end

        it 'removes a differently-capitalized placeholder funder' do
          @resource.contributors << StashDatacite::Contributor.new(contributor_name: 'N/a', contributor_type: 'funder', name_identifier_id: '0')
          @resource.update(publication_date: Date.today.to_s)
          ca = StashEngine::CurationActivity.create(resource_id: @resource.id, status: 'published', user: @user)
          ca.save
          @resource.reload
          expect(@resource.contributors).to be_blank
        end
      end

      context :email_orcid_invitations do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations).and_return(false)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation).and_return(true)
          @author = create(:author, author_first_name: 'Foo', author_last_name: 'Bar', author_email: 'foo.bar@example.edu', resource_id: @resource.id)
          # in theory stash_engine doesn't depend on datacite_engine, so mocking this out for now instead of bringing that engine in
          allow_any_instance_of(StashEngine::Author).to receive(:affiliation).and_return(
            { long_name: 'Western New Mexico University', ror_id: 'https://ror.org/00r5mr697' }.to_ostruct
          )
        end

        it 'calls email_orcid_invitations when published' do
          expect_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

        it 'does not call email_orcid_invitations to authors who already have an invitation' do
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return('fool.bar@example.edu')
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:identifier_id).and_return(@identifier.id)
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:email).and_return(@author.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

        it 'does not call email_orcid_invitations to authors who already have an ORCID registered' do
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return(@author.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

      end

      context :update_publication_flags do

        it 'sets flags for embargo' do
          create(:curation_activity, status: 'embargoed', resource: @resource)
          @identifier.reload
          @resource.reload
          expect(@identifier.pub_state).to eq('embargoed')
          expect(@resource.meta_view).to eq(true)
          expect(@resource.file_view).to eq(false)
        end

        it 'sets flags for published with file changes' do
          @resource.data_files << DataFile.create(file_state: 'created', upload_file_name: 'fun.cat', upload_file_size: 666)
          @resource.reload
          create(:curation_activity, resource: @resource, status: 'published')

          @identifier.reload
          @resource.reload

          expect(@identifier.pub_state).to eq('published')
          expect(@resource.meta_view).to eq(true)
          expect(@resource.file_view).to eq(true)
        end

        it 'sets flags for withdrawn' do
          create(:curation_activity, resource: @resource, status: 'withdrawn')
          @identifier.reload
          @resource.reload
          expect(@identifier.pub_state).to eq('withdrawn')
          expect(@resource.meta_view).to eq(false)
          expect(@resource.file_view).to eq(false)
        end
      end

      context :peer_review_status do
        it 'disables the default peer_review setting after publication' do
          @resource.hold_for_peer_review = true
          @resource.save
          create(:curation_activity, status: 'peer_review', resource: @resource)
          create(:curation_activity, status: 'published', resource: @resource)
          @resource.reload
          expect(@resource.hold_for_peer_review?).to eq(false)
        end
      end
    end

  end
end
